import Foundation
import Combine

@MainActor
class PenguinViewModel: ObservableObject {
    @Published var penguinExpression: PenguinExpression = .idle
    @Published var lastTranscribedText = ""
    @Published var lastResponse = ""
    @Published var isListening = false
    @Published var isThinking = false
    @Published var isWakingUp = false
    @Published var isManualTalkMode = false

    private let speechManager = SpeechManager()
    private let llmManager = LLMManager()
    private let voiceManager = VoiceManager()

    private var cancellables = Set<AnyCancellable>()
    private var silenceTimer: Timer?
    private var idleChatterTimer: Timer?

    private let idleLines = [
        "Bloop bloop! I am a very handsome penguin.",
        "Did you know penguins can't fly? But we do look great.",
        "I am practicing my best waddles.",
        "Knock knock. Who's there? Ice. Ice who? Ice to meet you!",
        "Fun fact: penguins love chilly adventures."
    ]

    init() {
        setupBindings()
        speechManager.requestPermissions()
        startIdleState()
    }

    private func setupBindings() {
        speechManager.$isListening
            .assign(to: &$isListening)

        speechManager.$transcribedText
            .sink { [weak self] text in
                guard let self = self else { return }
                self.lastTranscribedText = text
                // Accessing isWakingUp here is safe because this sink executes on the Main Actor context.
                if self.isWakingUp {
                    self.resetSilenceTimer()
                }
            }
            .store(in: &cancellables)

        speechManager.$keywordDetected
            .sink { [weak self] detected in
                guard let self = self else { return }
                // Accessing isWakingUp and isThinking here is safe within the MainActor context path.
                if detected && !self.isWakingUp && !self.isThinking {
                    self.handleKeywordDetected()
                }
            }
            .store(in: &cancellables)

        voiceManager.$isSpeaking
            .sink { [weak self] speaking in
                guard let self = self else { return }
                if speaking {
                    self.penguinExpression = .speaking
                }
            }
            .store(in: &cancellables)

        voiceManager.onFinishedSpeaking = { [weak self] in
            // Starting idle state must be safe on Main Actor context which this closure runs on.
            self?.startIdleState()
        }
    }

    func startIdleState() {
        silenceTimer?.invalidate()
        idleChatterTimer?.invalidate()
        isWakingUp = false
        isManualTalkMode = false
        lastResponse = ""
        speechManager.resetKeywordDetection()
        speechManager.clearTranscription()
        speechManager.startListening()
        penguinExpression = .idle
        scheduleIdleChatterTimer()
    }

    func startManualTalk() {
        idleChatterTimer?.invalidate()
        isManualTalkMode = true
        isWakingUp = true
        penguinExpression = .surprised
        lastTranscribedText = ""
        lastResponse = ""
        speechManager.resetKeywordDetection()
        speechManager.clearTranscription()
        speechManager.startListening()
    }

    func toggleManualTalk() {
        if isManualTalkMode || isWakingUp || isThinking {
            stopManualTalk()
        } else {
            startManualTalk()
        }
    }

    private func stopManualTalk() {
        silenceTimer?.invalidate()
        isWakingUp = false
        isManualTalkMode = false
        speechManager.stopListening()
        startIdleState()
    }

    private func handleKeywordDetected() {
        // Setting state directly within the main actor context is safe.
        idleChatterTimer?.invalidate()
        isWakingUp = true
        penguinExpression = .surprised
        resetSilenceTimer()
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                guard self.isWakingUp else { return }
                await self.processQuestion()
            }
        }
    }

    private func processQuestion() async {
        idleChatterTimer?.invalidate()
        let fullText = lastTranscribedText
        let keywords = ["penguini", "penguin", "penguino", "pingu", "hey penguini", "hi penguini"]

        var question = fullText

        // Find the first occurrence of any keyword and take the text after it
        var lowestIndex: String.Index?

        for kw in keywords {
            if let range = fullText.range(of: kw) {
                if lowestIndex == nil || range.lowerBound < lowestIndex! {
                    lowestIndex = range.lowerBound
                    question = String(fullText[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }

        guard !question.isEmpty else {
            startIdleState()
            return
        }

        if isManualTalkMode {
            question = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        isWakingUp = false
        isManualTalkMode = false
        speechManager.stopListening()
        lastTranscribedText = "" // Clear to show we're moving on
        isThinking = true
        penguinExpression = .thinking

        llmManager.generateResponseStream(prompt: question, partialHandler: { [weak self] partial in
            self?.lastResponse = partial
        }, completion: { [weak self] finalResponse in
            guard let self = self else { return }
            Task { @MainActor in // Ensure state updates happen on the main actor
                self.isThinking = false
                self.lastResponse = finalResponse
                self.setExpressionForResponse(finalResponse)
                self.voiceManager.speak(finalResponse)
                self.scheduleIdleChatterTimer()
            }
        })
    }

    private func scheduleIdleChatterTimer() {
        idleChatterTimer?.invalidate()
        idleChatterTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.maybeSpeakIdleChatter()
            }
        }
    }

    private func maybeSpeakIdleChatter() {
        guard !isThinking, !isWakingUp, !isManualTalkMode, !voiceManager.isSpeaking else { return }

        idleChatterTimer?.invalidate()

        let line = idleLines.randomElement() ?? "Bloop!"
        penguinExpression = .happy
        lastResponse = line
        voiceManager.speak(line)
    }

    private func setExpressionForResponse(_ response: String) {
        let lowerResponse = response.lowercased()

        if lowerResponse.contains("happy") || lowerResponse.contains("joy") || lowerResponse.contains("!") {
            penguinExpression = .happy
        } else if lowerResponse.contains("sorry") || lowerResponse.contains("don't know") {
            penguinExpression = .confused
        } else if lowerResponse.contains("wow") || lowerResponse.contains("amazing") {
            penguinExpression = .surprised
        } else {
            penguinExpression = .speaking
        }
    }
}
