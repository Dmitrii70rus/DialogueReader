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

                        if viewModel.playbackManager.isPlaying {
                            Button(viewModel.playbackManager.isPaused ? "Resume" : "Pause") {
                                viewModel.togglePauseResume()
                            }
                            .buttonStyle(.bordered)

                            Button("Stop") {
                                viewModel.stopPlayback()
                            }
                            .buttonStyle(.bordered)
                        }
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
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }

            if let message = viewModel.userMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .pickerStyle(.menu)

            if viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Paste or type text, then tap Play.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button("Play") {
                viewModel.playStandardNarration()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var dialogueModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dialogue")
                .font(.headline)

            HStack {
                Button("Split Into Segments") {
                    viewModel.splitTextIntoSegments()
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Button("Play Full Dialogue") {
                    viewModel.playAllSegments()
                }
                .buttonStyle(.borderedProminent)
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

                            Button("Play") {
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

            Button("Go Premium") {
                viewModel.showingPaywall = true
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    let purchase = PurchaseManager()
    let store = SpeakerStore()
    ContentView(viewModel: DialogueReaderViewModel(purchaseManager: purchase, speakerStore: store))
        .environmentObject(purchase)
}
