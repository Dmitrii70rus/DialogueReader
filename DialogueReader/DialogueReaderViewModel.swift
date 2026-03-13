import AVFoundation
import Foundation

@MainActor
final class DialogueReaderViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var segments: [DialogueSegment] = []
    @Published var speakers = Speaker.defaultSpeakers
    @Published var userMessage: String?
    @Published var showingPaywall = false
    @Published private(set) var fullDialoguePlayCount = 0

    let playbackManager = SpeechPlaybackManager()

    private let purchaseManager: PurchaseManager

    init(purchaseManager: PurchaseManager) {
        self.purchaseManager = purchaseManager
    }

    var availableVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().sorted {
            $0.language == $1.language ? $0.name < $1.name : $0.language < $1.language
        }
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

    func splitTextIntoSegments() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            userMessage = "Please enter some text before splitting into segments."
            segments = []
            return
        }

        let lines = inputText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            userMessage = "No non-empty lines were found to split."
            segments = []
            return
        }

        segments = lines.enumerated().map { index, text in
            let defaultSpeaker = speakers[index % speakers.count]
            return DialogueSegment(text: text, speakerID: defaultSpeaker.id)
        }

        userMessage = "Created \(segments.count) dialogue segment(s)."
    }

    func updateSpeaker(for segmentID: UUID, speakerID: Int) {
        guard let index = segments.firstIndex(where: { $0.id == segmentID }) else { return }
        segments[index].speakerID = speakerID
    }

    func updateVoice(for speakerID: Int, voiceIdentifier: String?) {
        guard let index = speakers.firstIndex(where: { $0.id == speakerID }) else { return }
        if let voiceIdentifier,
           AVSpeechSynthesisVoice(identifier: voiceIdentifier) == nil {
            userMessage = "That voice is no longer available on this device."
            return
        }

        speakers[index].selectedVoiceIdentifier = voiceIdentifier
    }

    func playSegment(_ segment: DialogueSegment) {
        Task {
            await playbackManager.play(text: segment.text, voice: voice(for: segment.speakerID))
        }
    }

    func playAllSegments() {
        guard !segments.isEmpty else {
            userMessage = "Split your text into dialogue segments first."
            return
        }

        guard canPlayFullDialogue else {
            showingPaywall = true
            return
        }

        if !purchaseManager.isPremiumUnlocked {
            fullDialoguePlayCount += 1
        }

        Task {
            for segment in segments {
                await playbackManager.play(text: segment.text, voice: voice(for: segment.speakerID))
            }
        }
    }

    func stopPlayback() {
        playbackManager.stop()
    }

    func paywallDescription() -> String {
        if purchaseManager.isPremiumUnlocked {
            return "Premium is active. Enjoy unlimited full-dialogue playback sessions."
        }
        return "Free users can run up to \(PurchaseManager.freePlayLimit) full-dialogue playback sessions after segmentation. Upgrade to premium for unlimited sessions."
    }

    private func voice(for speakerID: Int) -> AVSpeechSynthesisVoice? {
        speakers.first(where: { $0.id == speakerID })?.selectedVoice
    }
}
