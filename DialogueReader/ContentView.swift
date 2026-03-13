import AVFAudio
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

                    speechTuningSection
                    if viewModel.selectedMode == .standard {
                        standardModeSection
                    } else {
                        dialogueModeSection
                    }

                    speakerSetupSection
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
    }

    private var speechTuningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Speech")
                .font(.headline)

            VStack(alignment: .leading) {
                Text("Rate")
                Slider(value: Binding(
                    get: { Double(viewModel.speechRate) },
                    set: { viewModel.speechRate = Float($0) }
                ), in: 0.35...0.6)
            }

            VStack(alignment: .leading) {
                Text("Pitch")
                Slider(value: Binding(
                    get: { Double(viewModel.pitch) },
                    set: { viewModel.pitch = Float($0) }
                ), in: 0.7...1.4)
            }

            if viewModel.selectedMode == .dialogue {
                VStack(alignment: .leading) {
                    Text("Pause Between Segments: \(viewModel.pauseBetweenSegments.formatted(.number.precision(.fractionLength(1))))s")
                    Slider(value: $viewModel.pauseBetweenSegments, in: 0...1.0)
                }
            }
        }
    }

    private var standardModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Standard TTS")
                .font(.headline)

            Picker("Narrator", selection: $viewModel.standardSpeakerID) {
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

            playbackButtons(playAction: viewModel.playStandardNarration)
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

    private var speakerSetupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Speakers & Voices")
                .font(.headline)

            ForEach(viewModel.speakers) { speaker in
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Speaker Name", text: Binding(
                        get: { speaker.name },
                        set: { viewModel.renameSpeaker(speaker.id, name: $0) }
                    ))
                    .textFieldStyle(.roundedBorder)

                    Picker("Language", selection: Binding(
                        get: { speaker.preferredLanguageCode ?? "all" },
                        set: { viewModel.updateLanguage(for: speaker.id, languageCode: $0 == "all" ? nil : $0) }
                    )) {
                        Text("All Languages").tag("all")
                        ForEach(viewModel.availableLanguageCodes, id: \.self) { language in
                            Text(viewModel.languageDisplayName(for: language)).tag(language)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Voice", selection: Binding(
                        get: { speaker.selectedVoiceIdentifier ?? "default" },
                        set: { viewModel.updateVoice(for: speaker.id, voiceIdentifier: $0 == "default" ? nil : $0) }
                    )) {
                        Text("System Default").tag("default")
                        ForEach(viewModel.voices(for: speaker), id: \.identifier) { voice in
                            Text(voice.displayName).tag(voice.identifier)
                        }
                    }
                    .pickerStyle(.menu)

                    HStack {
                        Button("Preview Voice") {
                            viewModel.previewVoice(for: speaker.id)
                        }
                        .buttonStyle(.bordered)

                        Text("Enhanced voices may require iOS voice downloads.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .listStyle(.plain)
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }

            if let message = viewModel.userMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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

            HStack {
                Button("Go Premium") {
                    viewModel.showingPaywall = true
                }
                .buttonStyle(.bordered)

                Spacer()
            }
        }
    }

    private func playbackButtons(playAction: @escaping () -> Void) -> some View {
        HStack {
            Button("Play") {
                playAction()
            }
            .buttonStyle(.borderedProminent)

            Button(viewModel.playbackManager.isPaused ? "Resume" : "Pause") {
                viewModel.togglePauseResume()
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.playbackManager.isPlaying)

            Button("Stop") {
                viewModel.stopPlayback()
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.playbackManager.isPlaying)
        }
    }
}

#Preview {
    let purchase = PurchaseManager()
    ContentView(viewModel: DialogueReaderViewModel(purchaseManager: purchase))
        .environmentObject(purchase)
}
