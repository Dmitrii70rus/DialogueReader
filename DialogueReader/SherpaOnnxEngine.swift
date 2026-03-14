import Foundation

struct SherpaOnnxVoice: Identifiable, Hashable {
    let id: String
    let displayName: String
}

@MainActor
final class SherpaOnnxEngine {
    static let shared = SherpaOnnxEngine()

    private(set) var isAvailable: Bool = false
    private(set) var availabilityMessage: String = "Sherpa-ONNX runtime is not linked."

    private init() {
        configure()
    }

    var bundledVoices: [SherpaOnnxVoice] {
        [
            SherpaOnnxVoice(id: "en-us-default", displayName: "Sherpa EN-US Default")
        ]
    }

    private func configure() {
        #if canImport(SherpaOnnx)
        isAvailable = true
        availabilityMessage = "Sherpa-ONNX is available."
        #else
        isAvailable = false
        availabilityMessage = "Sherpa-ONNX package/model is not linked in this build; Apple TTS fallback will be used."
        #endif
    }

    func synthesizeToWav(text: String, voiceID: String) async throws -> URL {
        #if canImport(SherpaOnnx)
        throw NSError(domain: "SherpaOnnxEngine", code: -2, userInfo: [NSLocalizedDescriptionKey: "Implement concrete Sherpa model binding for this package version."])
        #else
        throw NSError(domain: "SherpaOnnxEngine", code: -1, userInfo: [NSLocalizedDescriptionKey: availabilityMessage])
        #endif
    }
}
