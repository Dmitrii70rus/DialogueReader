import AVFoundation
import Combine
import Foundation

@MainActor
final class DialogueReaderViewModel: ObservableObject {
    enum ReaderMode: String, CaseIterable, Identifiable {
        case standard = "Standard TTS"
        case dialogue = "Dialogue"

        var id: String { rawValue }
    }

    @Published var inputText = ""
    @Published var segments: [DialogueSegment] = []
    @Published var speakers = Speaker.defaultSpeakers
    @Published var selectedMode: ReaderMode = .standard

    @Published var userMessage: String?
    @Published var showingPaywall = false
    @Published private(set) var fullDialoguePlayCount = 0

    @Published var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate
    @Published var pitch: Float = 1.0
    @Published var pauseBetweenSegments: Double = 0.2

    @Published var standardSpeakerID: Int = 1

    let playbackManager = SpeechPlaybackManager()

    private let purchaseManager: PurchaseManager
    private var playbackTask: Task<Void, Never>?

    init(purchaseManager: PurchaseManager) {
        self.purchaseManager = purchaseManager
    }

    var availableVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().sorted { lhs, rhs in
            if lhs.language != rhs.language { return lhs.language < rhs.language }
            if lhs.quality != rhs.quality { return lhs.quality.rawValue > rhs.quality.rawValue }
            return lhs.name < rhs.name
        }
    }

    var availableLanguageCodes: [String] {
        Array(Set(availableVoices.map(\.language))).sorted()
    }

    var canPlayFullDialogue: Bool {
        purchaseManager.isPremiumUnlocked || fullDialoguePlayCount < PurchaseManager.freePlayLimit
    }

    var remainingFreeSessions: Int {
        max(0, PurchaseManager.freePlayLimit - fullDialoguePlayCount)
    }

    var hasText: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func languageDisplayName(for languageCode: String) -> String {
        let locale = Locale.current.localizedString(forIdentifier: languageCode) ?? languageCode
        return "\(locale) (\(languageCode))"
    }

    func voices(for speaker: Speaker) -> [AVSpeechSynthesisVoice] {
        guard let preferredLanguageCode = speaker.preferredLanguageCode,
              !preferredLanguageCode.isEmpty else {
            return availableVoices
        }

        return availableVoices.filter { $0.language == preferredLanguageCode }
    }

    func splitTextIntoSegments() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            userMessage = "Please enter text before splitting."
            segments = []
            return
        }

        let lines = inputText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            userMessage = "No non-empty lines were found."
            segments = []
            return
        }

        segments = lines.enumerated().map { index, text in
            let defaultSpeaker = speakers[index % speakers.count]
            return DialogueSegment(text: text, speakerID: defaultSpeaker.id)
        }

        userMessage = "Created \(segments.count) segments."
    }

    func updateSpeaker(for segmentID: UUID, speakerID: Int) {
        guard let index = segments.firstIndex(where: { $0.id == segmentID }) else { return }
        segments[index].speakerID = speakerID
    }

    func renameSpeaker(_ speakerID: Int, name: String) {
        guard let index = speakers.firstIndex(where: { $0.id == speakerID }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        speakers[index].name = trimmed.isEmpty ? "Speaker \(speakerID)" : trimmed
    }

    func updateLanguage(for speakerID: Int, languageCode: String?) {
        guard let index = speakers.firstIndex(where: { $0.id == speakerID }) else { return }
        speakers[index].preferredLanguageCode = languageCode

        guard let voiceIdentifier = speakers[index].selectedVoiceIdentifier,
              let selectedVoice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) else {
            return
        }

        if let languageCode, selectedVoice.language != languageCode {
            speakers[index].selectedVoiceIdentifier = nil
        }
    }

    func updateVoice(for speakerID: Int, voiceIdentifier: String?) {
        guard let index = speakers.firstIndex(where: { $0.id == speakerID }) else { return }
        if let voiceIdentifier,
           AVSpeechSynthesisVoice(identifier: voiceIdentifier) == nil {
            userMessage = "That voice is unavailable on this device."
            return
        }

        speakers[index].selectedVoiceIdentifier = voiceIdentifier

        if let selected = speakers[index].selectedVoice {
            speakers[index].preferredLanguageCode = selected.language
            if selected.quality == .default {
                userMessage = "Using standard voice quality. You can install enhanced voices in iOS Settings > Accessibility > Spoken Content > Voices."
            }
        }
    }

    func previewVoice(for speakerID: Int) {
        guard let speaker = speakers.first(where: { $0.id == speakerID }) else { return }
        let text = "Hello, I am \(speaker.name)."
        stopPlayback()
        playbackTask = Task {
            await playbackManager.play(text: text, voice: voice(for: speakerID), rate: speechRate, pitch: pitch)
        }
    }

    func playSegment(_ segment: DialogueSegment) {
        guard voice(for: segment.speakerID) != nil || selectedVoiceIdentifier(for: segment.speakerID) == nil else {
            userMessage = "The selected voice is unavailable. Choose another voice."
            return
        }

        stopPlayback()
        playbackTask = Task {
            await playbackManager.play(text: segment.text, voice: voice(for: segment.speakerID), rate: speechRate, pitch: pitch)
        }
    }

    func playStandardNarration() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            userMessage = "Please enter text to play."
            return
        }

        guard voice(for: standardSpeakerID) != nil || selectedVoiceIdentifier(for: standardSpeakerID) == nil else {
            userMessage = "The selected voice is unavailable."
            return
        }

        stopPlayback()
        playbackTask = Task {
            await playbackManager.play(text: trimmed, voice: voice(for: standardSpeakerID), rate: speechRate, pitch: pitch)
        }
    }

    func playAllSegments() {
        guard !segments.isEmpty else {
            userMessage = "Split your text into segments first."
            return
        }

        guard canPlayFullDialogue else {
            showingPaywall = true
            return
        }

        if !purchaseManager.isPremiumUnlocked {
            fullDialoguePlayCount += 1
        }

        stopPlayback()
        playbackTask = Task {
            for (index, segment) in segments.enumerated() {
                if Task.isCancelled { return }
                await playbackManager.play(text: segment.text, voice: voice(for: segment.speakerID), rate: speechRate, pitch: pitch)
                if index < segments.count - 1 {
                    let ns = UInt64(max(0, pauseBetweenSegments) * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: ns)
                }
            }
        }
    }

    func stopPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
        playbackManager.stop()
    }

    func togglePauseResume() {
        if playbackManager.isPaused {
            playbackManager.resume()
        } else {
            playbackManager.pause()
        }
    }

    func paywallDescription() -> String {
        if purchaseManager.isPremiumUnlocked {
            return "Premium is active. Enjoy unlimited full-dialogue playback sessions."
        }
        return "Free users can run up to \(PurchaseManager.freePlayLimit) full-dialogue playback sessions after segmentation. Upgrade to premium for unlimited sessions."
    }

    private func selectedVoiceIdentifier(for speakerID: Int) -> String? {
        speakers.first(where: { $0.id == speakerID })?.selectedVoiceIdentifier
    }

    private func voice(for speakerID: Int) -> AVSpeechSynthesisVoice? {
        speakers.first(where: { $0.id == speakerID })?.selectedVoice
    }
}
