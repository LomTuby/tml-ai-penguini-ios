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

    init() {
        setupBindings()
        speechManager.requestPermissions()
        startIdleState()
    }

    private func setupBindings() {
        speechManager.$isListening
            .assign(to: &$isListening)

        speechManager.$transcribedText
            .assign(to: &$lastTranscribedText)

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

        // Wait 3 seconds for the user to finish their question
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // Check if we are already thinking (prevent multiple triggers)
            if self.isWakingUp {
                self.processQuestion()
                self.isWakingUp = false
            }
        }
    }

    private func processQuestion() {
        let fullText = lastTranscribedText
        let keyword = "penguini"

        var question = fullText
        if let range = fullText.range(of: keyword) {
            question = String(fullText[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard !question.isEmpty else {
            startIdleState()
            return
        }

        speechManager.stopListening()
        isThinking = true
        penguinExpression = .thinking

        llmManager.generateResponse(prompt: question) { [weak self] response in
            self?.isThinking = false
            self?.lastResponse = response
            self?.setExpressionForResponse(response)
            self?.voiceManager.speak(response)
        }
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
