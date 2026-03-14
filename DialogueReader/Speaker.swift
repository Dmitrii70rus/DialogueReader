import AVFoundation
import Foundation

enum SpeechEngineType: String, CaseIterable, Codable, Identifiable {
    case sherpaOnnx
    case appleSystem

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sherpaOnnx: return "Natural Offline Voice (Recommended)"
        case .appleSystem: return "Apple System Voice (Fallback)"
        }
    }
}

enum SpeakerGender: String, CaseIterable, Codable, Identifiable {
    case unspecified
    case likelyFemale
    case likelyMale

    var id: String { rawValue }
}

enum VoiceQualityPreference: String, CaseIterable, Codable, Identifiable {
    case any
    case enhancedOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .any: return "Any"
        case .enhancedOnly: return "Enhanced/Premium"
        }
    }
}

struct Speaker: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var engine: SpeechEngineType
    var sherpaVoiceID: String?
    var selectedVoiceIdentifier: String?
    var preferredLanguageCode: String?
    var genderGrouping: SpeakerGender
    var speechRate: Float
    var pitch: Float
    var pauseAfterSegment: Double
    var volume: Float
    var qualityPreference: VoiceQualityPreference

    var selectedVoice: AVSpeechSynthesisVoice? {
        guard let selectedVoiceIdentifier else { return nil }
        return AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier)
    }

    static var defaultSpeakers: [Speaker] {
        [
            Speaker(
                id: UUID(),
                name: "Narrator",
                engine: .sherpaOnnx,
                sherpaVoiceID: "female-natural",
                selectedVoiceIdentifier: nil,
                preferredLanguageCode: "en-US",
                genderGrouping: .unspecified,
                speechRate: AVSpeechUtteranceDefaultSpeechRate,
                pitch: 1.0,
                pauseAfterSegment: 0.2,
                volume: 1.0,
                qualityPreference: .enhancedOnly
            ),
            Speaker(
                id: UUID(),
                name: "Speaker 2",
                engine: .sherpaOnnx,
                sherpaVoiceID: "female-natural",
                selectedVoiceIdentifier: nil,
                preferredLanguageCode: "en-US",
                genderGrouping: .unspecified,
                speechRate: AVSpeechUtteranceDefaultSpeechRate,
                pitch: 1.0,
                pauseAfterSegment: 0.2,
                volume: 1.0,
                qualityPreference: .enhancedOnly
            )
        ]
    }
}

extension AVSpeechSynthesisVoice {
    var qualityLabel: String {
        switch quality {
        case .default: return "Standard"
        case .enhanced: return "Enhanced"
        case .premium: return "Premium"
        @unknown default: return "Standard"
        }
    }

    var displayName: String {
        "\(name) • \(language) • \(qualityLabel)"
    }
}
