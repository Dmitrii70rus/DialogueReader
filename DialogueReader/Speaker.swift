import AVFoundation
import Foundation

struct Speaker: Identifiable, Hashable {
    let id: Int
    var name: String
    var selectedVoiceIdentifier: String?

    var selectedVoice: AVSpeechSynthesisVoice? {
        guard let selectedVoiceIdentifier else { return nil }
        return AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier)
    }

    static var defaultSpeakers: [Speaker] {
        [
            Speaker(id: 1, name: "Speaker 1", selectedVoiceIdentifier: nil),
            Speaker(id: 2, name: "Speaker 2", selectedVoiceIdentifier: nil),
            Speaker(id: 3, name: "Speaker 3", selectedVoiceIdentifier: nil),
            Speaker(id: 4, name: "Speaker 4", selectedVoiceIdentifier: nil)
        ]
    }
}

extension AVSpeechSynthesisVoice {
    var displayName: String {
        "\(name) (\(language))"
    }
}
