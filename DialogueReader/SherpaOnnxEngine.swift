import Foundation

@MainActor
final class SherpaOnnxEngine {
    static let shared = SherpaOnnxEngine()

    private(set) var isAvailable: Bool = false
    private(set) var availabilityMessage: String = "Sherpa-ONNX runtime is not linked."

    private init() {
        configure()
    }

    private func configure() {
        let hasModels = TTSModelManager.shared.isNeuralReady
        #if canImport(SherpaOnnx)
        isAvailable = hasModels
        availabilityMessage = hasModels
            ? "Sherpa-ONNX runtime and neural models are available."
            : "Sherpa runtime is linked but no models were found in /Models/TTS."
        #else
        isAvailable = false
        availabilityMessage = hasModels
            ? "Neural models are bundled, but Sherpa-ONNX runtime package is not linked."
            : "Sherpa-ONNX runtime and model assets are not linked in this build."
        #endif
    }

    func synthesizeToWav(text: String, voiceID: String) async throws -> URL {
        #if canImport(SherpaOnnx)
        _ = text
        _ = voiceID
        throw NSError(domain: "SherpaOnnxEngine", code: -2, userInfo: [NSLocalizedDescriptionKey: "Sherpa runtime is linked but synthesis binding is not implemented for this package version."])
        #else
        throw NSError(domain: "SherpaOnnxEngine", code: -1, userInfo: [NSLocalizedDescriptionKey: availabilityMessage])
        #endif
    }
}
