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
    private var audioPlayer: AVAudioPlayer?

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
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        audioPlayer?.stop()
        audioPlayer = nil
        continuation?.resume()
        continuation = nil
        playbackState = .idle
    }

    func pause() {
        if let audioPlayer, audioPlayer.isPlaying {
            audioPlayer.pause()
            playbackState = .paused
            return
        }

        guard synthesizer.isSpeaking else { return }
        if synthesizer.pauseSpeaking(at: .word) {
            playbackState = .paused
        }
    }

    func resume() {
        if let audioPlayer, !audioPlayer.isPlaying {
            audioPlayer.play()
            playbackState = .playing
            return
        }

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

    func playAudioFile(url: URL) async {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            audioPlayer = player
            player.delegate = self
            playbackState = .playing
            player.prepareToPlay()
            player.play()

            await withCheckedContinuation { continuation in
                self.continuation = continuation
            }
        } catch {
            continuation?.resume()
            continuation = nil
            playbackState = .idle
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

extension SpeechPlaybackManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            self?.audioPlayer = nil
            self?.continuation?.resume()
            self?.continuation = nil
            self?.playbackState = .idle
        }
    }
}
