import SwiftUI
import AVFAudio

struct ContentView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @StateObject var viewModel: DialogueReaderViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("DialogueReader")
                    .font(.largeTitle.bold())

                Text("Build line-based dialogue and play each line with a different speaker voice.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextEditor(text: $viewModel.inputText)
                    .padding(8)
                    .frame(minHeight: 140)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.quaternary, lineWidth: 1)
                    }

                HStack {
                    Button("Split into Segments") {
                        viewModel.splitTextIntoSegments()
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()

                    if viewModel.playbackManager.isPlaying {
                        Button("Stop") {
                            viewModel.stopPlayback()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if let message = viewModel.userMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if viewModel.segments.isEmpty {
                    ContentUnavailableView(
                        "No Dialogue Segments Yet",
                        systemImage: "text.quote",
                        description: Text(viewModel.hasText ? "Tap ‘Split into Segments’ to convert each non-empty line into one segment." : "Paste or type text to get started.")
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        Section("Segments") {
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
                                .padding(.vertical, 4)
                            }
                        }

                        Section("Speaker Voices") {
                            ForEach(viewModel.speakers) { speaker in
                                Picker(speaker.name, selection: Binding(
                                    get: { speaker.selectedVoiceIdentifier ?? "default" },
                                    set: { viewModel.updateVoice(for: speaker.id, voiceIdentifier: $0 == "default" ? nil : $0) }
                                )) {
                                    Text("System Default").tag("default")
                                    ForEach(viewModel.availableVoices, id: \.identifier) { voice in
                                        Text(voice.displayName).tag(voice.identifier)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }

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

                    HStack {
                        Button("Play Full Dialogue") {
                            viewModel.playAllSegments()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Go Premium") {
                            viewModel.showingPaywall = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $viewModel.showingPaywall) {
            PaywallView()
                .environmentObject(purchaseManager)
        }
    }
}

#Preview {
    let purchase = PurchaseManager()
    ContentView(viewModel: DialogueReaderViewModel(purchaseManager: purchase))
        .environmentObject(purchase)
}
