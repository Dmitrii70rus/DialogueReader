import Foundation

struct DialogueSegment: Identifiable, Hashable {
    let id = UUID()
    var text: String
    var speakerID: UUID
}
