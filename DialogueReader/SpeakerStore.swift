import AVFoundation
import Combine
import Foundation

@MainActor
final class SpeakerStore: ObservableObject {
    @Published private(set) var speakers: [Speaker] = []

    private let defaults: UserDefaults
    private let storageKey = "dialoguereader.speakers.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func addSpeaker() -> Speaker {
        let speaker = Speaker(
            id: UUID(),
            name: "Speaker \(speakers.count + 1)",
            selectedVoiceIdentifier: nil,
            preferredLanguageCode: nil,
            genderGrouping: .unspecified,
            speechRate: AVSpeechUtteranceDefaultSpeechRate,
            pitch: 1.0,
            pauseAfterSegment: 0.2,
            volume: 1.0,
            qualityPreference: .any
        )
        speakers.append(speaker)
        save()
        return speaker
    }

    func updateSpeaker(_ speaker: Speaker) {
        guard let idx = speakers.firstIndex(where: { $0.id == speaker.id }) else { return }
        speakers[idx] = speaker
        save()
    }

    func deleteSpeaker(_ speaker: Speaker) {
        speakers.removeAll { $0.id == speaker.id }
        if speakers.isEmpty {
            speakers = Speaker.defaultSpeakers
        }
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Speaker].self, from: data),
              !decoded.isEmpty else {
            speakers = Speaker.defaultSpeakers
            save()
            return
        }
        speakers = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(speakers) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
