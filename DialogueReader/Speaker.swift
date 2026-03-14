import AVFoundation
import Foundation

enum SpeechEngineType: String, CaseIterable, Codable, Identifiable {
    case sherpaOnnx
    case appleSystem

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sherpaOnnx: return "Sherpa-ONNX (Offline)"
        case .appleSystem: return "Apple System Voice"
        }
    }
}

enum SpeakerGender: String, CaseIterable, Codable, Identifiable {
    case unspecified
    case likelyFemale
    case likelyMale

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unspecified: return "Unspecified"
        case .likelyFemale: return "Likely Female"
        case .likelyMale: return "Likely Male"
        }
    }
}

enum VoiceQualityPreference: String, CaseIterable, Codable, Identifiable {
    case any
    case enhancedOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .any: return "Any"
        case .enhancedOnly: return "Enhanced Only"
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


    enum CodingKeys: String, CodingKey {
        case id, name, engine, sherpaVoiceID, selectedVoiceIdentifier, preferredLanguageCode, genderGrouping, speechRate, pitch, pauseAfterSegment, volume, qualityPreference
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        engine = try c.decodeIfPresent(SpeechEngineType.self, forKey: .engine) ?? .appleSystem
        sherpaVoiceID = try c.decodeIfPresent(String.self, forKey: .sherpaVoiceID)
        selectedVoiceIdentifier = try c.decodeIfPresent(String.self, forKey: .selectedVoiceIdentifier)
        preferredLanguageCode = try c.decodeIfPresent(String.self, forKey: .preferredLanguageCode)
        genderGrouping = try c.decodeIfPresent(SpeakerGender.self, forKey: .genderGrouping) ?? .unspecified
        speechRate = try c.decodeIfPresent(Float.self, forKey: .speechRate) ?? AVSpeechUtteranceDefaultSpeechRate
        pitch = try c.decodeIfPresent(Float.self, forKey: .pitch) ?? 1.0
        pauseAfterSegment = try c.decodeIfPresent(Double.self, forKey: .pauseAfterSegment) ?? 0.2
        volume = try c.decodeIfPresent(Float.self, forKey: .volume) ?? 1.0
        qualityPreference = try c.decodeIfPresent(VoiceQualityPreference.self, forKey: .qualityPreference) ?? .any
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(engine, forKey: .engine)
        try c.encodeIfPresent(sherpaVoiceID, forKey: .sherpaVoiceID)
        try c.encodeIfPresent(selectedVoiceIdentifier, forKey: .selectedVoiceIdentifier)
        try c.encodeIfPresent(preferredLanguageCode, forKey: .preferredLanguageCode)
        try c.encode(genderGrouping, forKey: .genderGrouping)
        try c.encode(speechRate, forKey: .speechRate)
        try c.encode(pitch, forKey: .pitch)
        try c.encode(pauseAfterSegment, forKey: .pauseAfterSegment)
        try c.encode(volume, forKey: .volume)
        try c.encode(qualityPreference, forKey: .qualityPreference)
    }
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
                sherpaVoiceID: "en-us-default",
                selectedVoiceIdentifier: nil,
                preferredLanguageCode: nil,
                genderGrouping: .unspecified,
                speechRate: AVSpeechUtteranceDefaultSpeechRate,
                pitch: 1.0,
                pauseAfterSegment: 0.2,
                volume: 1.0,
                qualityPreference: .any
            ),
            Speaker(
                id: UUID(),
                name: "Speaker 2",
                engine: .appleSystem,
                sherpaVoiceID: nil,
                selectedVoiceIdentifier: nil,
                preferredLanguageCode: nil,
                genderGrouping: .unspecified,
                speechRate: AVSpeechUtteranceDefaultSpeechRate,
                pitch: 1.0,
                pauseAfterSegment: 0.2,
                volume: 1.0,
                qualityPreference: .any
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
