import Foundation

struct NeuralVoice: Identifiable, Hashable {
    let id: String
    let displayName: String
    let languageCode: String
    let modelFile: String
    let tokensFile: String

    var modelPathInBundle: String { "Models/TTS/\(modelFile)" }
    var tokensPathInBundle: String { "Models/TTS/\(tokensFile)" }
}

@MainActor
final class TTSModelManager {
    static let shared = TTSModelManager()

    private(set) var neuralVoices: [NeuralVoice] = []
    private(set) var isNeuralReady = false
    private(set) var statusMessage = "Neural voice models are not bundled in this build."

    private init() {
        loadBundledModels()
    }

    func loadBundledModels() {
        let catalog: [NeuralVoice] = [
            NeuralVoice(id: "female-natural", displayName: "Female Natural", languageCode: "en-US", modelFile: "female-natural.onnx", tokensFile: "female-natural.tokens"),
            NeuralVoice(id: "male-natural", displayName: "Male Natural", languageCode: "en-US", modelFile: "male-natural.onnx", tokensFile: "male-natural.tokens"),
            NeuralVoice(id: "female-warm", displayName: "Female Warm", languageCode: "en-US", modelFile: "female-warm.onnx", tokensFile: "female-warm.tokens"),
            NeuralVoice(id: "male-deep", displayName: "Male Deep", languageCode: "en-US", modelFile: "male-deep.onnx", tokensFile: "male-deep.tokens")
        ]

        let available = catalog.filter { voice in
            Bundle.main.url(forResource: voice.modelFile, withExtension: nil, subdirectory: "Models/TTS") != nil
            && Bundle.main.url(forResource: voice.tokensFile, withExtension: nil, subdirectory: "Models/TTS") != nil
        }

        neuralVoices = available
        isNeuralReady = !available.isEmpty
        statusMessage = isNeuralReady
            ? "Natural offline neural voices are available."
            : "Neural voice models were not found in /Models/TTS. Falling back to Apple system voices."
    }

    func voice(with id: String?) -> NeuralVoice? {
        guard let id else { return nil }
        return neuralVoices.first(where: { $0.id == id })
    }
}
