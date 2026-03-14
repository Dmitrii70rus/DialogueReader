import AVFAudio
import SwiftUI

struct SpeakerManagementView: View {
    @ObservedObject var viewModel: DialogueReaderViewModel
    @State private var editingSpeaker: Speaker?

    var body: some View {
        NavigationStack {
            List {
                Section("Saved Speakers") {
                    ForEach(viewModel.speakers) { speaker in
                        Button {
                            editingSpeaker = speaker
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(speaker.name)
                                    Text(summary(for: speaker))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Manage Speakers")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { viewModel.showingSpeakerManager = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editingSpeaker = viewModel.addSpeaker()
                    } label: {
                        Label("Add Speaker", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editingSpeaker) { speaker in
                SpeakerEditorView(viewModel: viewModel, speaker: speaker)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteSpeaker(viewModel.speakers[index])
        }
    }

    private func summary(for speaker: Speaker) -> String {
        if speaker.engine == .sherpaOnnx {
            let neuralName = viewModel.availableNeuralVoices.first(where: { $0.id == speaker.sherpaVoiceID })?.displayName ?? "Natural Offline Voice"
            return "\(neuralName) • Neural"
        }

        let voiceName = speaker.selectedVoice?.name ?? "System fallback"
        return "\(voiceName) • Apple"
    }
}

struct SpeakerEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DialogueReaderViewModel
    @State var speaker: Speaker

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $speaker.name)

                    Picker("Voice Engine", selection: $speaker.engine) {
                        ForEach(viewModel.availableSpeechEngines) { engine in
                            Text(engine.title).tag(engine)
                        }
                    }

                    Text(viewModel.sherpaStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Language", selection: Binding(
                        get: { speaker.preferredLanguageCode ?? "en-US" },
                        set: { speaker.preferredLanguageCode = $0 }
                    )) {
                        ForEach(viewModel.availableLanguageCodes, id: \.self) { language in
                            Text(viewModel.languageDisplayName(for: language)).tag(language)
                        }
                    }
                }

                Section("Voice") {
                    if speaker.engine == .sherpaOnnx {
                        Picker("Voice", selection: Binding(
                            get: { speaker.sherpaVoiceID ?? viewModel.availableNeuralVoices.first?.id ?? "" },
                            set: { speaker.sherpaVoiceID = $0 }
                        )) {
                            ForEach(viewModel.availableNeuralVoices) { voice in
                                Text(voice.displayName).tag(voice.id)
                            }
                        }
                    } else {
                        Picker("Voice", selection: Binding(
                            get: { currentVoiceSelection(for: speaker) },
                            set: { speaker.selectedVoiceIdentifier = $0 == "default" ? nil : $0 }
                        )) {
                            Text("Apple Auto").tag("default")
                            ForEach(viewModel.groupedVoices(for: speaker)) { group in
                                Section(group.title) {
                                    ForEach(group.voices, id: \.identifier) { voice in
                                        Text(voice.name).tag(voice.identifier)
                                    }
                                }
                            }
                        }
                    }

                    Button("Preview Voice") {
                        viewModel.previewVoice(for: speaker)
                    }
                }

                if speaker.engine == .appleSystem {
                    Section("Apple Fallback Tuning") {
                        VStack(alignment: .leading) {
                            Text("Rate")
                            Slider(value: Binding(
                                get: { Double(speaker.speechRate) },
                                set: { speaker.speechRate = Float($0) }
                            ), in: 0.35...0.6)
                        }

                        VStack(alignment: .leading) {
                            Text("Pitch")
                            Slider(value: Binding(
                                get: { Double(speaker.pitch) },
                                set: { speaker.pitch = Float($0) }
                            ), in: 0.7...1.4)
                        }

                        VStack(alignment: .leading) {
                            Text("Volume")
                            Slider(value: Binding(
                                get: { Double(speaker.volume) },
                                set: { speaker.volume = Float($0) }
                            ), in: 0...1)
                        }
                    }
                }

                Section("Pause") {
                    VStack(alignment: .leading) {
                        Text("Pause After Segment: \(speaker.pauseAfterSegment.formatted(.number.precision(.fractionLength(1))))s")
                        Slider(value: $speaker.pauseAfterSegment, in: 0...1)
                    }
                }
            }
            .navigationTitle("Speaker")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        var sanitized = speaker
                        let trimmed = sanitized.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        sanitized.name = trimmed.isEmpty ? "Speaker" : trimmed

                        if sanitized.engine == .appleSystem,
                           let identifier = sanitized.selectedVoiceIdentifier,
                           AVSpeechSynthesisVoice(identifier: identifier) == nil {
                            sanitized.selectedVoiceIdentifier = nil
                        }

                        if sanitized.engine == .sherpaOnnx,
                           viewModel.availableNeuralVoices.contains(where: { $0.id == sanitized.sherpaVoiceID }) == false {
                            sanitized.sherpaVoiceID = viewModel.availableNeuralVoices.first?.id
                        }

                        viewModel.saveSpeaker(sanitized)
                        dismiss()
                    }
                }
            }
        }
    }

    private func currentVoiceSelection(for speaker: Speaker) -> String {
        guard let selected = speaker.selectedVoiceIdentifier else {
            return "default"
        }

        let validIDs = Set(viewModel.voices(for: speaker).map(\.identifier))
        return validIDs.contains(selected) ? selected : "default"
    }
}
