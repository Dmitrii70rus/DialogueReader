import AVFoundation
import Foundation

protocol DialogueExportManaging {
    func exportDialogueAudio(segments: [DialogueSegment], speakers: [Speaker]) async throws -> URL
    func exportNarrationAudio(text: String, speaker: Speaker) async throws -> URL
}

struct AppleDialogueExportManager: DialogueExportManaging {
    func exportDialogueAudio(segments: [DialogueSegment], speakers: [Speaker]) async throws -> URL {
        let resolved = segments.compactMap { segment -> (String, Speaker)? in
            guard let speaker = speakers.first(where: { $0.id == segment.speakerID }) else { return nil }
            return (segment.text, speaker)
        }

        guard !resolved.isEmpty else {
            throw ExportError.noContent
        }

        return try await writeAudioFile(from: resolved)
    }

    func exportNarrationAudio(text: String, speaker: Speaker) async throws -> URL {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ExportError.noContent
        }

        return try await writeAudioFile(from: [(trimmed, speaker)])
    }

    private func writeAudioFile(from chunks: [(text: String, speaker: Speaker)]) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("dialogue-export-\(UUID().uuidString)")
            .appendingPathExtension("caf")

        let writer = SpeechAudioFileWriter(outputURL: outputURL)

        for (index, chunk) in chunks.enumerated() {
            try await writer.append(
                text: chunk.text,
                voice: chunk.speaker.selectedVoice,
                rate: chunk.speaker.speechRate,
                pitch: chunk.speaker.pitch,
                volume: chunk.speaker.volume
            )

            if index < chunks.count - 1 {
                try await writer.appendSilence(seconds: max(0, chunk.speaker.pauseAfterSegment))
            }
        }

        return outputURL
    }
}

private actor SpeechAudioFileWriter {
    private let outputURL: URL
    private let synthesizer = AVSpeechSynthesizer()
    private var audioFile: AVAudioFile?
    private var outputFormat: AVAudioFormat?

    init(outputURL: URL) {
        self.outputURL = outputURL
    }

    func append(text: String, voice: AVSpeechSynthesisVoice?, rate: Float, pitch: Float, volume: Float) async throws {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = min(max(rate, 0.35), 0.6)
        utterance.pitchMultiplier = min(max(pitch, 0.5), 2.0)
        utterance.volume = min(max(volume, 0.0), 1.0)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var hasResumed = false

            synthesizer.write(utterance) { buffer in
                guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(throwing: ExportError.unexpectedBuffer)
                    }
                    return
                }

                if pcmBuffer.frameLength == 0 {
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume()
                    }
                    return
                }

                do {
                    try self.write(pcmBuffer: pcmBuffer)
                } catch {
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    func appendSilence(seconds: Double) async throws {
        guard seconds > 0, let format = outputFormat else { return }

        let sampleRate = format.sampleRate
        let frameCapacity = AVAudioFrameCount(max(1, seconds * sampleRate))
        guard let silence = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            throw ExportError.silenceGenerationFailed
        }

        silence.frameLength = frameCapacity
        for channel in 0..<Int(format.channelCount) {
            silence.floatChannelData?[channel].initialize(repeating: 0, count: Int(frameCapacity))
        }
        try write(pcmBuffer: silence)
    }

    private func write(pcmBuffer: AVAudioPCMBuffer) throws {
        if audioFile == nil {
            outputFormat = pcmBuffer.format
            audioFile = try AVAudioFile(forWriting: outputURL, settings: pcmBuffer.format.settings)
        }

        try audioFile?.write(from: pcmBuffer)
    }
}

enum ExportError: LocalizedError {
    case noContent
    case unexpectedBuffer
    case silenceGenerationFailed

    var errorDescription: String? {
        switch self {
        case .noContent:
            return "Nothing to export yet."
        case .unexpectedBuffer:
            return "Could not synthesize audio buffer for export."
        case .silenceGenerationFailed:
            return "Could not generate pause audio while exporting."
        }
    }
}
