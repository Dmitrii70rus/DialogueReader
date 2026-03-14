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
            engine: .appleSystem,
            sherpaVoiceID: nil,
            selectedVoiceIdentifier: bestDefaultVoiceIdentifier(),
            preferredLanguageCode: "en-US",
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
            speakers = defaultSpeakersWithBestVoices()
        }
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Speaker].self, from: data),
              !decoded.isEmpty else {
            speakers = defaultSpeakersWithBestVoices()
            save()
            return
        }

        speakers = decoded.map { speaker in
            var item = speaker
            if let id = item.selectedVoiceIdentifier,
               AVSpeechSynthesisVoice(identifier: id) == nil {
                item.selectedVoiceIdentifier = nil
            }
            if item.engine == .appleSystem, item.selectedVoiceIdentifier == nil {
                item.selectedVoiceIdentifier = bestDefaultVoiceIdentifier(for: item.preferredLanguageCode)
            }
            return item
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(speakers) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func defaultSpeakersWithBestVoices() -> [Speaker] {
        var defaults = Speaker.defaultSpeakers
        for index in defaults.indices {
            defaults[index].selectedVoiceIdentifier = bestDefaultVoiceIdentifier(for: defaults[index].preferredLanguageCode)
            if defaults[index].preferredLanguageCode == nil {
                defaults[index].preferredLanguageCode = "en-US"
            }
        }
        return defaults
    }

    private func bestDefaultVoiceIdentifier(for preferredLanguage: String? = "en-US") -> String? {
        let voices = AVSpeechSynthesisVoice.speechVoices()

        func match(_ voice: AVSpeechSynthesisVoice, _ language: String?) -> Bool {
            guard let language else { return true }
            if voice.language == language { return true }
            return language.count >= 2 && voice.language.hasPrefix(String(language.prefix(2)))
        }

        if let premium = voices.first(where: { match($0, preferredLanguage) && $0.quality == .premium }) {
            return premium.identifier
        }
        if let enhanced = voices.first(where: { match($0, preferredLanguage) && $0.quality == .enhanced }) {
            return enhanced.identifier
        }
        if let standard = voices.first(where: { match($0, preferredLanguage) && $0.quality == .default }) {
            return standard.identifier
        }
        return voices.first?.identifier
    }
}
