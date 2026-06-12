import Foundation
import AVFoundation

@MainActor
final class VoiceManager: NSObject, ObservableObject {
    private let synthesizer: AVSpeechSynthesizer
    private let delegateProxy: SpeechDelegateProxy
    @Published var isSpeaking = false

    var onFinishedSpeaking: (() -> Void)?
    var onSpeechPowerChanged: ((Float) -> Void)?

    override init() {
        self.synthesizer = AVSpeechSynthesizer()
        self.delegateProxy = SpeechDelegateProxy()
        super.init()

        delegateProxy.onStart = { [weak self] in
            self?.isSpeaking = true
        }
        delegateProxy.onFinish = { [weak self] in
            self?.isSpeaking = false
            self?.onFinishedSpeaking?()
        }

        synthesizer.delegate = delegateProxy
    }

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.35
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
}

private final class SpeechDelegateProxy: NSObject, AVSpeechSynthesizerDelegate {
    var onStart: (() -> Void)?
    var onFinish: (() -> Void)?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.onStart?()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.onFinish?()
        }
    }
}
