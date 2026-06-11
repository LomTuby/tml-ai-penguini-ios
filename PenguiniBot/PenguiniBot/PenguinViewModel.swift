import Foundation
import Combine

class PenguinViewModel: ObservableObject {
    @Published var penguinExpression: PenguinExpression = .idle
    @Published var lastTranscribedText = ""
    @Published var lastResponse = ""
    @Published var isListening = false
    @Published var isThinking = false
    @Published var isWakingUp = false

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
                if self?.isWakingUp == true {
                    self?.resetSilenceTimer()
                }
            }
            .store(in: &cancellables)

        speechManager.$keywordDetected
            .sink { [weak self] detected in
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
            self?.startIdleState()
        }
    }

    func startIdleState() {
        isWakingUp = false
        lastResponse = ""
        speechManager.resetKeywordDetection()
        speechManager.clearTranscription()
        speechManager.startListening()
        penguinExpression = .idle
    }

    private func handleKeywordDetected() {
        isWakingUp = true
        penguinExpression = .surprised
        resetSilenceTimer()
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            guard let self = self, self.isWakingUp else { return }
            self.processQuestion()
        }
    }

    private func processQuestion() {
        let fullText = lastTranscribedText
        let keywords = ["penguini", "penguin", "penguino", "pingu", "hey penguini", "hi penguini"]

        var question = fullText

        // Find the first occurrence of any keyword and take the text after it
        var lowestIndex: String.Index?
        var matchedKeywordLength = 0

        for kw in keywords {
            if let range = fullText.range(of: kw) {
                if lowestIndex == nil || range.lowerBound < lowestIndex! {
                    lowestIndex = range.lowerBound
                    matchedKeywordLength = kw.count
                    question = String(fullText[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }

        guard !question.isEmpty else {
            startIdleState()
            return
        }

        isWakingUp = false
        speechManager.stopListening()
        lastTranscribedText = "" // Clear to show we're moving on
        isThinking = true
        penguinExpression = .thinking

        llmManager.generateResponseStream(prompt: question, partialHandler: { [weak self] partial in
            self?.lastResponse = partial
        }, completion: { [weak self] finalResponse in
            self?.isThinking = false
            self?.lastResponse = finalResponse
            self?.setExpressionForResponse(finalResponse)
            self?.voiceManager.speak(finalResponse)
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
