import AVFoundation
import Combine
import Foundation

@MainActor
final class SpeechPlaybackManager: NSObject, ObservableObject {
    enum PlaybackState {
        case idle
        case playing
        case paused
    }

    @Published private(set) var playbackState: PlaybackState = .idle

    private let synthesizer = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Never>?

    var isPlaying: Bool {
        playbackState != .idle
    }

    var isPaused: Bool {
        playbackState == .paused
    }

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        continuation?.resume()
        continuation = nil
        playbackState = .idle
    }

    func pause() {
        guard synthesizer.isSpeaking else { return }
        if synthesizer.pauseSpeaking(at: .word) {
            playbackState = .paused
        }
    }

    func resume() {
        guard synthesizer.isPaused else { return }
        synthesizer.continueSpeaking()
        playbackState = .playing
    }

    func play(text: String, voice: AVSpeechSynthesisVoice?, rate: Float, pitch: Float, volume: Float) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = voice
        utterance.rate = min(max(rate, 0.35), 0.6)
        utterance.pitchMultiplier = min(max(pitch, 0.5), 2.0)
        utterance.prefersAssistiveTechnologySettings = true
        utterance.preUtteranceDelay = 0.02
        utterance.volume = min(max(volume, 0.0), 1.0)

        playbackState = .playing
        synthesizer.speak(utterance)

        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    private func handleDidFinish() {
        continuation?.resume()
        continuation = nil
        if !synthesizer.isSpeaking {
            playbackState = .idle
        }
    }

    private func handleDidCancel() {
        continuation?.resume()
        continuation = nil
        playbackState = .idle
    }
}

extension SpeechPlaybackManager: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.handleDidFinish()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.handleDidCancel()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.playbackState = .paused
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.playbackState = .playing
        }
    }
}
