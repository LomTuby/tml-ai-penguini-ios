import Foundation
import Speech
import AVFoundation

class SpeechManager: ObservableObject {
    @Published var isListening = false
    @Published var transcribedText = ""
    @Published var keywordDetected = false

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private let keyword = "penguini"

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in
            AVAudioApplication.requestRecordPermission { _ in }
        }
    }

    func startListening() {
        guard !audioEngine.isRunning else { return }

        do {
            try setupAudioEngine()
            startRecognition()
            isListening = true
        } catch {
            print("Speech recognition setup failed: \(error.localizedDescription)")
        }
    }

    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isListening = false
    }

    func clearTranscription() {
        transcribedText = ""
    }

    func resetKeywordDetection() {
        keywordDetected = false
    }

    private func setupAudioEngine() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func startRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString.lowercased()
                self.transcribedText = text

                if !self.keywordDetected && text.contains(self.keyword) {
                    self.keywordDetected = true
                }
            }

            if error != nil || result?.isFinal == true {
                self.stopListening()
            }
        }
    }
}
