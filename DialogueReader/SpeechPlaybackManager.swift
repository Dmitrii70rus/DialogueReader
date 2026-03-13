import AVFoundation
import Foundation
import Combine

@MainActor
final class SpeechPlaybackManager: NSObject, ObservableObject {
    @Published private(set) var isPlaying = false

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
    }

    func play(text: String, voice: AVSpeechSynthesisVoice?) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.prefersAssistiveTechnologySettings = true

        isPlaying = true
        synthesizer.speak(utterance)

        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
}

extension SpeechPlaybackManager: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            continuation?.resume()
            continuation = nil
            if !synthesizer.isSpeaking {
                isPlaying = false
            }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            continuation?.resume()
            continuation = nil
            isPlaying = false
        }
    }
}
