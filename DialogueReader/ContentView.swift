import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @StateObject var viewModel: DialogueReaderViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("DialogueReader")
                        .font(.largeTitle.bold())

                    Picker("Mode", selection: $viewModel.selectedMode) {
                        ForEach(DialogueReaderViewModel.ReaderMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextEditor(text: $viewModel.inputText)
                        .padding(8)
                        .frame(minHeight: 150)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.quaternary, lineWidth: 1)
                        }

                    HStack {
                        Button("Manage Speakers") {
                            viewModel.showingSpeakerManager = true
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }

                    if viewModel.selectedMode == .standard {
                        standardModeSection
                    } else {
                        dialogueModeSection
                    }

                    if let message = viewModel.userMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    monetizationSection
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $viewModel.showingPaywall) {
            PaywallView()
                .environmentObject(purchaseManager)
        }
        .onChange(of: purchaseManager.isPremiumUnlocked) { _, isUnlocked in
            if isUnlocked {
                viewModel.showingPaywall = false
            }
        }
        .sheet(isPresented: $viewModel.showingSpeakerManager) {
            SpeakerManagementView(viewModel: viewModel)
        }
    }

    private var standardModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Standard TTS")
                .font(.headline)

            Picker("Narrator", selection: Binding(
                get: { viewModel.standardSpeakerID ?? viewModel.speakers.first?.id ?? UUID() },
                set: { viewModel.standardSpeakerID = $0 }
            )) {
                ForEach(viewModel.speakers) { speaker in
                    Text(speaker.name).tag(speaker.id)
                }
            }
            .pickerStyle(.menu)

            if viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Paste or type text, then tap Play.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            narrationTransportControls
        }
    }

    private var narrationTransportControls: some View {
        HStack {
            switch viewModel.playbackManager.playbackState {
            case .idle:
                Button("Play Narration") {
                    viewModel.playStandardNarration()
                }
                .buttonStyle(.borderedProminent)
            case .playing:
                Button("Pause") {
                    viewModel.togglePauseResume()
                }
                .buttonStyle(.bordered)

                Button("Stop") {
                    viewModel.stopPlayback()
                }
                .buttonStyle(.borderedProminent)
            case .paused:
                Button("Resume") {
                    viewModel.togglePauseResume()
                }
                .buttonStyle(.bordered)

                Button("Stop") {
                    viewModel.stopPlayback()
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
    }

    private var dialogueModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dialogue")
                .font(.headline)

            Toggle("Auto-assign alternating speakers", isOn: $viewModel.autoAssignAlternatingSpeakers)
                .font(.subheadline)

            if viewModel.autoAssignAlternatingSpeakers {
                Picker("Starting Speaker", selection: Binding(
                    get: { viewModel.autoAssignStartSpeakerID ?? viewModel.speakers.first?.id ?? UUID() },
                    set: { viewModel.autoAssignStartSpeakerID = $0 }
                )) {
                    ForEach(viewModel.speakers) { speaker in
                        Text(speaker.name).tag(speaker.id)
                    }
                }
                .pickerStyle(.menu)
            }

            SelectionAssignView(
                text: $viewModel.inputText,
                speakers: viewModel.speakers,
                onAssign: { selectedText, speakerID in
                    viewModel.assignSelectedTextAsSegment(selectedText, to: speakerID)
                }
            )

            HStack {
                Button("Split Into Segments") {
                    viewModel.splitTextIntoSegments()
                }
                .buttonStyle(.bordered)

                Spacer()

                if viewModel.playbackManager.playbackState == .idle {
                    Button("Play Full Dialogue") {
                        viewModel.playAllSegments()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(viewModel.playbackManager.playbackState == .paused ? "Resume" : "Pause") {
                        viewModel.togglePauseResume()
                    }
                    .buttonStyle(.bordered)

                    Button("Stop") {
                        viewModel.stopPlayback()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if viewModel.segments.isEmpty {
                ContentUnavailableView(
                    "No Segments Yet",
                    systemImage: "text.quote",
                    description: Text(viewModel.hasText ? "Tap Split Into Segments to convert each non-empty line into dialogue." : "Paste or type text to create dialogue segments.")
                )
            } else {
                ForEach(viewModel.segments) { segment in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(segment.text)
                            .font(.body)

                        HStack {
                            Picker("Speaker", selection: Binding(
                                get: { segment.speakerID },
                                set: { viewModel.updateSpeaker(for: segment.id, speakerID: $0) }
                            )) {
                                ForEach(viewModel.speakers) { speaker in
                                    Text(speaker.name).tag(speaker.id)
                                }
                            }
                            .pickerStyle(.menu)

                            Spacer()

                            Button("Play Line") {
                                viewModel.playSegment(segment)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var monetizationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if purchaseManager.isPremiumUnlocked {
                Text("Premium unlocked: unlimited full-dialogue playback")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("Free full-dialogue sessions remaining: \(viewModel.remainingFreeSessions)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button(purchaseManager.isPremiumUnlocked ? "Premium Active" : "Go Premium") {
                if !purchaseManager.isPremiumUnlocked {
                    viewModel.showingPaywall = true
                }
            }
            .buttonStyle(.bordered)
            .disabled(purchaseManager.isPremiumUnlocked)
        }
    }
}

#Preview {
    let purchase = PurchaseManager()
    let store = SpeakerStore()
    ContentView(viewModel: DialogueReaderViewModel(purchaseManager: purchase, speakerStore: store))
        .environmentObject(purchase)
}
