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
                .action: ModelConfig(provider: "google", model: "gemini-2.0-flash-lite"),
                .experienceVectors: ModelConfig(
                    provider: "openrouter", model: "x-ai/grok-3-mini-beta"),
                .experienceWeb: ModelConfig(
                    provider: "openrouter", model: "ai21/jamba-1.6-mini"),
                .intention: ModelConfig(provider: "openai", model: "gpt-4.1-mini"),
                .observation: ModelConfig(provider: "groq", model: "qwen-qwq-32b"),
                .understanding: ModelConfig(
                    provider: "openrouter", model: "x-ai/grok-3-mini-beta"),
                .yield: ModelConfig(provider: "openai", model: "gpt-4.1"),
            ]
        }
    }
}
