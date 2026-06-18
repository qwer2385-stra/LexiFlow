import AVFoundation

/// TTS（文本转语音）管理器
/// 封装 AVSpeechSynthesizer，支持英文发音
final class TTSManager: NSObject, ObservableObject {

    // MARK: - Published

    /// 是否正在朗读
    @Published var isSpeaking: Bool = false

    // MARK: - Private

    private let synthesizer = AVSpeechSynthesizer()

    /// 语速（0.0 ~ 1.0）
    var rate: Float = AVSpeechUtteranceDefaultSpeechRate

    /// 音调（0.5 ~ 2.0）
    var pitchMultiplier: Float = 1.0

    // MARK: - Init

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - 朗读

    /// 朗读指定文本
    func speak(text: String, language: String = "en-US") {
        // 如果正在朗读，先停止
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        utterance.pitchMultiplier = pitchMultiplier
        utterance.volume = 1.0

        synthesizer.speak(utterance)
        isSpeaking = true
    }

    /// 停止朗读
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    /// 暂停朗读
    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
        }
    }

    /// 继续朗读
    func resume() {
        synthesizer.continueSpeaking()
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TTSManager: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
