import SwiftUI

struct ModelConfigView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentConfigs: [Phase: ModelConfig] = [:]
    @State private var apiKeys: [String: String] = [:]
    @State private var newModelProvider: String = "google"
    @State private var newModelName: String = ""
    @State private var showResetAlert = false

    private let providers = ["google", "openrouter", "anthropic", "groq", "openai", "bedrock"]

    @State private var dynamicModelsByProvider: [String: [String]] = [
        "google": ["gemini-2.0-flash-lite", "gemini-2.0-flash", "gemini-2.5-flash-preview-04-17", "gemini-2.5-pro-exp-03-25", "gemini-2.5-pro-preview-03-25"],
        "openrouter": [
            "ai21/jamba-1.6-mini", "x-ai/grok-3-mini-beta", "qwen/qwen3-30b-a3b", "qwen/qwen3-8b:free", "qwen/qwen3-14b", "qwen/qwen3-32b", "qwen/qwen3-235b-a22b", "thudm/glm-z1-rumination-32b", "thudm/glm-z1-9b:free", "google/gemini-2.5-flash-preview:thinking", "tngtech/deepseek-r1t-chimera:free", "agentica-org/deepcoder-14b-preview:free"
        ],
        "anthropic": [
            "claude-3-5-haiku-latest", "claude-3-5-sonnet-latest", "claude-3-7-sonnet-latest",
        ],
        "groq": ["qwen-qwq-32b", "meta-llama/llama-4-scout-17b-16e-instruct", "qwen-2.5-coder-32b", "deepseek-r1-distill-qwen-32b", "meta-llama/llama-4-maverick-17b-128e-instruct", "llama-3.1-8b-instant", "mistral-saba-24b"],
        "openai": ["gpt-4.1", "gpt-4.1-mini", "gpt-4.1-nano", "gpt-4o-mini-search-preview", "gpt-4o", "o3-mini"],
        "bedrock": ["anthropic.claude-3-5-sonnet-20241022-v2:0", "anthropic.claude-3-5-haiku-20241022-v1:0", "anthropic.claude-3-opus-20240229-v1:0", "meta.llama3-2-90b-instruct-v1:0", "meta.llama3-2-11b-instruct-v1:0"],
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Model Configuration") {
                    Text("Configure the AI models used for each phase of the PostChain workflow.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }

                ForEach(Phase.allCases) { phase in
                    Section(phase.description) {
                        Picker("Provider", selection: providerBinding(for: phase)) {
                            ForEach(providers, id: \.self) { provider in
                                Text(provider.capitalized).tag(provider)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Model", selection: modelBinding(for: phase)) {
                            if let provider = currentConfigs[phase]?.provider,
                                let models = dynamicModelsByProvider[provider]
                            {
                                ForEach(models, id: \.self) { model in
                                    Text(model).tag(model)
                                }
                            }
                        }
                        .pickerStyle(.menu)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Temperature")
                                Spacer()
                                Text(
                                    String(
                                        format: "%.2f", temperatureBinding(for: phase).wrappedValue)
                                )
                                .foregroundColor(.secondary)
                            }
                            Slider(value: temperatureBinding(for: phase), in: 0...1, step: 0.01)
                        }
                    }
                }

                Section("Add Custom Model") {
                    Picker("Provider", selection: $newModelProvider) {
                        ForEach(providers, id: \.self) { provider in
                            Text(provider.capitalized).tag(provider)
                        }
                    }
                    TextField("Custom Model Name", text: $newModelName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Button("Save Custom Model") {
                        saveCustomModel()
                    }
                    .disabled(newModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("API Keys") {
                    Text(
                        "Enter API keys for the selected providers. Keys are stored locally and sent with each request."
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)

                    ForEach(providers, id: \.self) { provider in
                        SecureField(
                            "\(provider.capitalized) API Key", text: apiKeyBinding(for: provider))
                    }
                }

                Section {
                    Button(action: {
                        showResetAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Reset to Defaults")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Model Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCustomModels()
                currentConfigs = ModelConfigManager.shared.loadModelConfigs()

                for provider in providers {
                    if let savedKey = UserDefaults.standard.string(forKey: "apiKey_\(provider)") {
                        apiKeys[provider] = savedKey
                    }
                }
            }
            .alert("Reset to Defaults", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetToDefaults()
                }
            } message: {
                Text("This will reset all model configurations to their default values.")
            }
            .onChange(of: currentConfigs) { _, _ in
                saveChanges()
            }
        }
    }

    private func providerBinding(for phase: Phase) -> Binding<String> {
        Binding<String>(
            get: { currentConfigs[phase]?.provider ?? "google" },
            set: { newProvider in
                var config =
                    currentConfigs[phase]
                    ?? ModelConfig(provider: newProvider, model: "", temperature: 0.33)
                config.provider = newProvider
                currentConfigs[phase] = config
            }
        )
    }

    private func modelBinding(for phase: Phase) -> Binding<String> {
        Binding<String>(
            get: { currentConfigs[phase]?.model ?? "" },
            set: { newModel in
                var config =
                    currentConfigs[phase]
                    ?? ModelConfig(provider: "openrouter", model: newModel, temperature: 0.33)
                config.model = newModel
                currentConfigs[phase] = config
            }
        )
    }

    private func temperatureBinding(for phase: Phase) -> Binding<Double> {
        Binding<Double>(
            get: { currentConfigs[phase]?.temperature ?? 0.33 },
            set: { newTemp in
                var config =
                    currentConfigs[phase]
                    ?? ModelConfig(provider: "openrouter", model: "", temperature: newTemp)
                config.temperature = newTemp
                currentConfigs[phase] = config
            }
        )
    }

    private func apiKeyBinding(for provider: String) -> Binding<String> {
        Binding<String>(
            get: { apiKeys[provider] ?? "" },
            set: { apiKeys[provider] = $0 }
        )
    }

    private func saveCustomModel() {
        let trimmedModelName = newModelName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedModelName.isEmpty else { return }

        let key = "customModels_\(newModelProvider)"
        var currentCustomModels = UserDefaults.standard.stringArray(forKey: key) ?? []

        if !currentCustomModels.contains(trimmedModelName) {
            currentCustomModels.append(trimmedModelName)
            UserDefaults.standard.set(currentCustomModels, forKey: key)
            loadCustomModels()
            newModelName = ""
        }
    }

    private func loadCustomModels() {
        var updatedModels = [
            "google": ["gemini-2.0-flash-lite", "gemini-2.0-flash", "gemini-2.5-flash-preview-04-17", "gemini-2.5-pro-exp-03-25", "gemini-2.5-pro-preview-03-25"],
            "openrouter": [
                "ai21/jamba-1.6-mini", "x-ai/grok-3-mini-beta", "qwen/qwen3-30b-a3b", "qwen/qwen3-8b:free", "qwen/qwen3-14b", "qwen/qwen3-32b", "qwen/qwen3-235b-a22b", "thudm/glm-z1-rumination-32b", "thudm/glm-z1-9b:free", "google/gemini-2.5-flash-preview:thinking", "tngtech/deepseek-r1t-chimera:free", "agentica-org/deepcoder-14b-preview:free"
            ],
            "anthropic": [
                "claude-3-5-haiku-latest", "claude-3-5-sonnet-latest", "claude-3-7-sonnet-latest",
            ],
            "groq": ["qwen-qwq-32b", "meta-llama/llama-4-scout-17b-16e-instruct", "qwen-2.5-coder-32b", "deepseek-r1-distill-qwen-32b", "meta-llama/llama-4-maverick-17b-128e-instruct", "llama-3.1-8b-instant", "mistral-saba-24b"],
            "openai": ["gpt-4.1", "gpt-4.1-mini", "gpt-4.1-nano", "gpt-4o-mini-search-preview", "gpt-4o", "o3-mini"],
            "bedrock": ["anthropic.claude-3-5-sonnet-20241022-v2:0", "anthropic.claude-3-5-haiku-20241022-v1:0", "anthropic.claude-3-opus-20240229-v1:0", "meta.llama3-2-90b-instruct-v1:0", "meta.llama3-2-11b-instruct-v1:0"],
        ]

        for provider in providers {
            let key = "customModels_\(provider)"
            if let customModels = UserDefaults.standard.stringArray(forKey: key) {
                if updatedModels[provider] == nil {
                    updatedModels[provider] = []
                }
                for model in customModels {
                    if !(updatedModels[provider]?.contains(model) ?? false) {
                        updatedModels[provider]?.append(model)
                    }
                }
            }
        }
        dynamicModelsByProvider = updatedModels
    }

    private func saveChanges() {
        for phase in Phase.allCases {
            if var config = currentConfigs[phase] {
                config.openaiApiKey = apiKeys["openai"]
                config.anthropicApiKey = apiKeys["anthropic"]
                config.googleApiKey = apiKeys["google"]
                config.mistralApiKey = apiKeys["mistral"]
                config.awsAccessKeyId = apiKeys["bedrock_access_key"]
                config.awsSecretAccessKey = apiKeys["bedrock_secret_key"]
                config.awsRegion = apiKeys["bedrock_region"]
                config.openrouterApiKey = apiKeys["openrouter"]
                config.groqApiKey = apiKeys["groq"]
                currentConfigs[phase] = config
            }
        }
        ModelConfigManager.shared.saveModelConfigs(currentConfigs)

        for (provider, key) in apiKeys {
            if !key.isEmpty {
                UserDefaults.standard.set(key, forKey: "apiKey_\(provider)")
            } else {
                UserDefaults.standard.removeObject(forKey: "apiKey_\(provider)")
            }
        }
    }

    private func resetToDefaults() {
        currentConfigs = ModelConfigManager.shared.loadModelConfigs()
        apiKeys.removeAll()
        saveChanges()
    }
}

#Preview {
    ModelConfigView()
}
