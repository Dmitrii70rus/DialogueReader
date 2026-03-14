import AVFoundation
import Combine
import Foundation

@MainActor
final class DialogueReaderViewModel: ObservableObject {
    struct VoiceLanguageGroup: Identifiable {
        let languageCode: String
        let title: String
        let voices: [AVSpeechSynthesisVoice]

        var id: String { languageCode }
    }

    enum ReaderMode: String, CaseIterable, Identifiable {
        case standard = "Standard TTS"
        case dialogue = "Dialogue"

        var id: String { rawValue }
    }

    @Published var inputText = ""
    @Published var segments: [DialogueSegment] = []
    @Published var selectedMode: ReaderMode = .standard

    @Published var userMessage: String?
    @Published var showingPaywall = false
    @Published var showingSpeakerManager = false
    @Published private(set) var fullDialoguePlayCount = 0

    @Published var standardSpeakerID: UUID?
    @Published var autoAssignAlternatingSpeakers = true
    @Published var autoAssignStartSpeakerID: UUID?

    let playbackManager = SpeechPlaybackManager()

    private let purchaseManager: PurchaseManager
    private let speakerStore: SpeakerStore
    private var playbackTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    init(purchaseManager: PurchaseManager, speakerStore: SpeakerStore) {
        self.purchaseManager = purchaseManager
        self.speakerStore = speakerStore
        standardSpeakerID = speakerStore.speakers.first?.id
        autoAssignStartSpeakerID = speakerStore.speakers.first?.id

        speakerStore.$speakers
            .sink { [weak self] speakers in
                guard let self else { return }
                guard !speakers.isEmpty else { return }

                if self.standardSpeakerID == nil || speakers.contains(where: { $0.id == self.standardSpeakerID }) == false {
                    self.standardSpeakerID = speakers.first?.id
                }

                let availableSpeakerIDs = Set(speakers.map(\.id))
                self.segments = self.segments.map {
                    var item = $0
                    if availableSpeakerIDs.contains(item.speakerID) == false,
                       let fallbackID = speakers.first?.id {
                        item.speakerID = fallbackID
                    }
                    return item
                }
            }
            .store(in: &cancellables)
    }

    var speakers: [Speaker] {
        speakerStore.speakers
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

    var hasHighQualityVoicesInstalled: Bool {
        availableVoices.contains { $0.quality == .enhanced || $0.quality == .premium }
    }

    var highQualityVoiceHint: String {
        if hasHighQualityVoicesInstalled {
            return "Tip: Choose Enhanced or Premium voices for the most natural local playback."
        }

        return "Higher-quality Apple voices may need downloading in Settings > Accessibility > Spoken Content > Voices."
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

    /// AVSpeechSynthesisVoice does not provide reliable explicit gender metadata.
    /// We keep this clearly heuristic for browsing assistance only.
    func inferredGender(for voice: AVSpeechSynthesisVoice) -> SpeakerGender {
        let value = "\(voice.name.lowercased()) \(voice.identifier.lowercased())"
        if value.contains("female") || value.contains("woman") {
            return .likelyFemale
        }
        if value.contains("male") || value.contains("man") {
            return .likelyMale
        }
        return .unspecified
    }

    func voices(for speaker: Speaker) -> [AVSpeechSynthesisVoice] {
        availableVoices.filter { voice in
            let languageMatch: Bool = {
                guard let language = speaker.preferredLanguageCode, !language.isEmpty else { return true }
                return voice.language == language
            }()

            let qualityMatch: Bool = {
                switch speaker.qualityPreference {
                case .any:
                    return true
                case .enhancedOnly:
                    return voice.quality == .enhanced || voice.quality == .premium
                }
            }()

            let genderMatch: Bool = {
                switch speaker.genderGrouping {
                case .unspecified:
                    return true
                case .likelyFemale:
                    return inferredGender(for: voice) == .likelyFemale
                case .likelyMale:
                    return inferredGender(for: voice) == .likelyMale
                }
            }()

            return languageMatch && qualityMatch && genderMatch
        }
    }

    func groupedVoices(for speaker: Speaker) -> [VoiceLanguageGroup] {
        let grouped = Dictionary(grouping: voices(for: speaker), by: \.language)
        return grouped.keys.sorted().map { code in
            VoiceLanguageGroup(
                languageCode: code,
                title: languageDisplayName(for: code),
                voices: grouped[code, default: []].sorted { lhs, rhs in
                    if lhs.quality != rhs.quality { return lhs.quality.rawValue > rhs.quality.rawValue }
                    return lhs.name < rhs.name
                }
            )
        }
    }

    func voiceSubtitle(for voice: AVSpeechSynthesisVoice) -> String {
        let gender = inferredGender(for: voice)
        switch gender {
        case .unspecified:
            return voice.qualityLabel
        case .likelyFemale:
            return "Likely Female • \(voice.qualityLabel)"
        case .likelyMale:
            return "Likely Male • \(voice.qualityLabel)"
        }
    }

    func splitTextIntoSegments() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            userMessage = "Please enter text before splitting."
            segments = []
            return
        }

        guard let fallbackSpeakerID = speakers.first?.id else {
            userMessage = "Create at least one speaker first."
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

        let startID = autoAssignStartSpeakerID ?? fallbackSpeakerID
        let startIndex = speakers.firstIndex(where: { $0.id == startID }) ?? 0

        segments = lines.enumerated().map { index, text in
            let speakerID: UUID
            if autoAssignAlternatingSpeakers, !speakers.isEmpty {
                let idx = (startIndex + index) % speakers.count
                speakerID = speakers[idx].id
            } else {
                speakerID = fallbackSpeakerID
            }
            return DialogueSegment(text: text, speakerID: speakerID)
        }

        userMessage = "Created \(segments.count) segments."
    }


    func assignSelectedTextAsSegment(_ selectedText: String, to speakerID: UUID) {
        let trimmed = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            userMessage = "Select non-empty text to assign a speaker."
            return
        }

        segments.append(DialogueSegment(text: trimmed, speakerID: speakerID))
        userMessage = "Added selected text as a new segment."
    }

    func updateSpeaker(for segmentID: UUID, speakerID: UUID) {
        guard let index = segments.firstIndex(where: { $0.id == segmentID }) else { return }
        segments[index].speakerID = speakerID
    }

    func saveSpeaker(_ speaker: Speaker) {
        speakerStore.updateSpeaker(speaker)
    }

    func addSpeaker() -> Speaker {
        speakerStore.addSpeaker()
    }

    func deleteSpeaker(_ speaker: Speaker) {
        speakerStore.deleteSpeaker(speaker)
    }

    func previewVoice(for speaker: Speaker) {
        let text = "Hello, this is a preview of the selected voice."
        stopPlayback()
        playbackTask = Task {
            await playTextWithSpeaker(text: text, speaker: speaker)
        }
    }

    func playSegment(_ segment: DialogueSegment) {
        guard let speaker = speaker(for: segment.speakerID) else {
            userMessage = "This segment references a removed speaker."
            return
        }

        if speaker.selectedVoiceIdentifier != nil && resolvedVoice(for: speaker) == nil {
            userMessage = "\(speaker.name)'s selected voice is unavailable."
            return
        }

        stopPlayback()
        playbackTask = Task {
            await playTextWithSpeaker(text: segment.text, speaker: speaker)
        }
    }

    func playStandardNarration() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            userMessage = "Please enter text to play."
            return
        }

        guard let speaker = standardSpeaker else {
            userMessage = "Please create a speaker first."
            return
        }

        stopPlayback()
        playbackTask = Task {
            await playTextWithSpeaker(text: trimmed, speaker: speaker)
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
                guard let speaker = speaker(for: segment.speakerID) else { continue }

                await playTextWithSpeaker(text: segment.text, speaker: speaker)

                if index < segments.count - 1 {
                    let ns = UInt64(max(0, speaker.pauseAfterSegment) * 1_000_000_000)
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


    private func playTextWithSpeaker(text: String, speaker: Speaker) async {
        if speaker.engine == .sherpaOnnx {
            let sherpa = SherpaOnnxEngine.shared
            if sherpa.isAvailable {
                let voiceID = speaker.sherpaVoiceID ?? sherpa.bundledVoices.first?.id ?? "en-us-default"
                if let url = try? await sherpa.synthesizeToWav(text: text, voiceID: voiceID) {
                    await playbackManager.playAudioFile(url: url)
                    return
                }
            }

            userMessage = "Sherpa-ONNX is unavailable in this build; using Apple voice fallback."
        }

        await playbackManager.play(
            text: text,
            voice: resolvedVoice(for: speaker),
            rate: speaker.speechRate,
            pitch: speaker.pitch,
            volume: speaker.volume
        )
    }

    func paywallDescription() -> String {
        if purchaseManager.isPremiumUnlocked {
            return "Premium is active. Enjoy unlimited full-dialogue playback sessions."
        }
        return "Free users can run up to \(PurchaseManager.freePlayLimit) full-dialogue playback sessions after segmentation. Upgrade to premium for unlimited sessions."
    }

    private var standardSpeaker: Speaker? {
        guard let standardSpeakerID else { return speakers.first }
        return speaker(for: standardSpeakerID) ?? speakers.first
    }

    private func speaker(for speakerID: UUID) -> Speaker? {
        speakers.first(where: { $0.id == speakerID })
    }

    func bestVoiceIdentifierForDefaultSpeaker() -> String? {
        if let premiumEnglish = availableVoices.first(where: { ($0.language.hasPrefix("en")) && $0.quality == .premium }) {
            return premiumEnglish.identifier
        }
        if let enhancedEnglish = availableVoices.first(where: { ($0.language.hasPrefix("en")) && $0.quality == .enhanced }) {
            return enhancedEnglish.identifier
        }
        if let standardEnglish = availableVoices.first(where: { ($0.language.hasPrefix("en")) && $0.quality == .default }) {
            return standardEnglish.identifier
        }
        return availableVoices.first?.identifier
    }

    private func resolvedVoice(for speaker: Speaker) -> AVSpeechSynthesisVoice? {
        if let selected = speaker.selectedVoice {
            return selected
        }

        let candidates = voices(for: speaker)

        if let premium = candidates.first(where: { $0.quality == .premium }) {
            return premium
        }
        if let enhanced = candidates.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }

        if let bestIdentifier = bestVoiceIdentifierForDefaultSpeaker() {
            return AVSpeechSynthesisVoice(identifier: bestIdentifier)
        }
        return candidates.first
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
