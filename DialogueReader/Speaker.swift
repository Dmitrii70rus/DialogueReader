import AVFoundation
import Foundation

struct Speaker: Identifiable, Hashable {
    let id: Int
    var name: String
    var selectedVoiceIdentifier: String?
    var preferredLanguageCode: String?

    var selectedVoice: AVSpeechSynthesisVoice? {
        guard let selectedVoiceIdentifier else { return nil }
        return AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier)
    }

    static var defaultSpeakers: [Speaker] {
        [
            Speaker(id: 1, name: "Speaker 1", selectedVoiceIdentifier: nil, preferredLanguageCode: nil),
            Speaker(id: 2, name: "Speaker 2", selectedVoiceIdentifier: nil, preferredLanguageCode: nil),
            Speaker(id: 3, name: "Speaker 3", selectedVoiceIdentifier: nil, preferredLanguageCode: nil),
            Speaker(id: 4, name: "Speaker 4", selectedVoiceIdentifier: nil, preferredLanguageCode: nil)
        ]
    }
}

extension AVSpeechSynthesisVoice {
    var qualityLabel: String {
        switch quality {
        case .default: return "Standard"
        case .enhanced: return "Enhanced"
        @unknown default: return "Standard"
        }
    }

    var displayName: String {
        "\(name) • \(language) • \(qualityLabel)"
    }
}
