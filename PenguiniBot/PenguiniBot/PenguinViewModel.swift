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
                self?.lastTranscribedText = text
                // Accessing isWakingUp here should be fine as it's within the MainActor context path of this sink execution.
                if self?.isWakingUp == true {
                    self?.resetSilenceTimer()
                }
            }
            .store(in: &cancellables)

        speechManager.$keywordDetected
            .sink { [weak self] detected in
                // Accessing isWakingUp and isThinking here should be fine within the MainActor context path.
                if detected && self?.isWakingUp == false && self?.isThinking == false {
                    self?.handleKeywordDetected()
                }
            }
            .store(in: &cancellables)

        voiceManager.$isSpeaking
            .sink { [weak self] speaking in
                if speaking {
                    self?.penguinExpression = .speaking
                }
            }
            .store(in: &cancellables)

        voiceManager.onFinishedSpeaking = { [weak self] in
            // Starting idle state must be safe on Main Actor context which this closure runs on.
            self?.startIdleState()
        }
    }

    func startIdleState() {
        isWakingUp = false
        isManualTalkMode = false
        lastResponse = ""
        speechManager.resetKeywordDetection()
        speechManager.clearTranscription()
        speechManager.startListening()
        penguinExpression = .idle
    }

    func startManualTalk() {
        isManualTalkMode = true
        isWakingUp = true
        penguinExpression = .surprised
        lastTranscribedText = ""
        lastResponse = ""
        speechManager.resetKeywordDetection()
        speechManager.clearTranscription()
        speechManager.startListening()
    }

    private func handleKeywordDetected() {
        // Setting state directly within the main actor context is safe.
        isWakingUp = true
        penguinExpression = .surprised
        resetSilenceTimer()
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            // Ensure 'self' exists and is on the Main Actor before accessing properties
            guard let self = self else { return }
            guard self.isWakingUp else { return } // Robust check for safety
            self.processQuestion()
        }
    }

    private func processQuestion() {
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
            guard let self = self else { return } // Added guard for safety
            self.isThinking = false
            self.lastResponse = finalResponse
            self.setExpressionForResponse(finalResponse)
            self.voiceManager.speak(finalResponse)
        })
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
