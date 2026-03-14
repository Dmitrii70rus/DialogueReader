import Foundation

protocol DialogueExportManaging {
    func exportAudio(for segments: [DialogueSegment], speakers: [Speaker]) async throws -> URL
}

struct DialogueExportNotImplementedManager: DialogueExportManaging {
    enum ExportError: LocalizedError {
        case notImplemented

        var errorDescription: String? {
            "Audio export is not available in this MVP. The architecture includes an export manager protocol for a future iteration."
        }
    }

    func exportAudio(for segments: [DialogueSegment], speakers: [Speaker]) async throws -> URL {
        throw ExportError.notImplemented
    }
}
