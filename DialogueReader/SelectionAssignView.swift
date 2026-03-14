import SwiftUI
import UIKit

struct SelectionAssignView: View {
    @Binding var text: String
    let speakers: [Speaker]
    let onAssign: (String, UUID) -> Void

    @State private var selectedText: String = ""
    @State private var selectedSpeakerID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Assign Speaker to Selection")
                .font(.headline)

            SelectionTextView(text: $text, selectedText: $selectedText)
                .frame(minHeight: 140)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary, lineWidth: 1))

            HStack {
                Picker("Speaker", selection: Binding(
                    get: { selectedSpeakerID ?? speakers.first?.id ?? UUID() },
                    set: { selectedSpeakerID = $0 }
                )) {
                    ForEach(speakers) { speaker in
                        Text(speaker.name).tag(speaker.id)
                    }
                }
                .pickerStyle(.menu)

                Button("Assign Selection") {
                    guard let id = selectedSpeakerID ?? speakers.first?.id else { return }
                    onAssign(selectedText, id)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || speakers.isEmpty)
            }

            if !selectedText.isEmpty {
                Text("Selected: \(selectedText)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

struct SelectionTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var selectedText: String

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.font = UIFont.preferredFont(forTextStyle: .body)
        tv.delegate = context.coordinator
        tv.isScrollEnabled = true
        tv.backgroundColor = .clear
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        let parent: SelectionTextView

        init(_ parent: SelectionTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard let range = textView.selectedTextRange else {
                parent.selectedText = ""
                return
            }
            parent.selectedText = textView.text(in: range) ?? ""
        }
    }
}
