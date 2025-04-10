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
           let configs = try? JSONDecoder().decode([Phase: ModelConfig].self, from: data) {
            return configs
        } else {
            // Provide sensible defaults if none saved
            return [
                .action: ModelConfig(provider: "google", model: "gemini-2.0-flash-lite"),
                .experienceVectors: ModelConfig(provider: "openrouter", model: "ai21/jamba-1.6-mini"),
                .experienceWeb: ModelConfig(provider: "openrouter", model: "openrouter/quasar-alpha"),
                .intention: ModelConfig(provider: "google", model: "gemini-2.0-flash"),
                .observation: ModelConfig(provider: "groq", model: "qwen-qwq-32b"),
                .understanding: ModelConfig(provider: "openrouter", model: "openrouter/quasar-alpha"),
                .yield: ModelConfig(provider: "google", model: "gemini-2.5-pro-exp-03-25")
            ]
        }
    }
}
