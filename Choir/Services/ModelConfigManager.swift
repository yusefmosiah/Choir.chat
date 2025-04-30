import Foundation

class ModelConfigManager {
    static let shared = ModelConfigManager()

    private let userDefaultsKey = "globalActiveModelConfig"

    private init() {}

    func saveModelConfigs(_ configs: [Phase: ModelConfig]) {
        if let data = try? JSONEncoder().encode(configs) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    func loadModelConfigs() -> [Phase: ModelConfig] {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
            let configs = try? JSONDecoder().decode([Phase: ModelConfig].self, from: data)
        {
            return configs
        } else {
            // Provide sensible defaults if none saved
            return [
                .action: ModelConfig(provider: "openai", model: "gpt-4.1-nano"),
                .experienceVectors: ModelConfig(provider: "google", model: "gemini-2.0-flash-lite"),
                .experienceWeb: ModelConfig(provider: "groq", model: "meta-llama/llama-4-scout-17b-16e-instruct"),
                .intention: ModelConfig(provider: "google", model: "gemini-2.0-flash"),
                .observation: ModelConfig(provider: "openai", model: "gpt-4.1-nano"),
                .understanding: ModelConfig(
                    provider: "groq", model: "meta-llama/llama-4-maverick-17b-128e-instruct"),
                .yield: ModelConfig(provider: "google", model: "gemini-2.5-flash-preview-04-17"),
            ]
        }
    }
}
