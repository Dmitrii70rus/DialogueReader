import AVFoundation
import Combine
import Foundation

@MainActor
final class SpeechPlaybackManager: NSObject, ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var isPaused = false

    private let synthesizer = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        continuation?.resume()
        continuation = nil
        isPlaying = false
        isPaused = false
    }

    func pause() {
        guard synthesizer.isSpeaking else { return }
        isPaused = synthesizer.pauseSpeaking(at: .word)
    }

    func resume() {
        guard synthesizer.isPaused else { return }
        synthesizer.continueSpeaking()
        isPaused = false
    }

    func play(text: String, voice: AVSpeechSynthesisVoice?, rate: Float, pitch: Float, volume: Float) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = voice
        utterance.rate = min(max(rate, 0.35), 0.6)
        utterance.pitchMultiplier = min(max(pitch, 0.5), 2.0)
        utterance.prefersAssistiveTechnologySettings = true
        utterance.volume = min(max(volume, 0.0), 1.0)

        isPlaying = true
        isPaused = false
        synthesizer.speak(utterance)

        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
}

@preconcurrency
extension SpeechPlaybackManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        continuation?.resume()
        continuation = nil
        if !self.synthesizer.isSpeaking {
            isPlaying = false
            isPaused = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        continuation?.resume()
        continuation = nil
        isPlaying = false
        isPaused = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        isPaused = true
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        isPaused = false
    }
}
