import SwiftUI

struct ModelConfigView: View {
    // Thread reference to modify
    @ObservedObject var thread: ChoirThread
    @Environment(\.dismiss) private var dismiss

    // List of available providers and models
    private let providers = ["google", "openrouter", "anthropic", "groq", "openai"]

    // Available models by provider - now a @State variable to include custom models
    @State private var dynamicModelsByProvider: [String: [String]] = [
        "google": ["gemini-2.0-flash-lite", "gemini-2.0-flash", "gemini-2.5-pro-exp-03-25"],
        "openrouter": ["ai21/jamba-1.6-mini", "openrouter/quasar-alpha", "mistralai/mixtral-8x7b"],
        "anthropic": ["claude-3-haiku-20240307", "claude-3-sonnet-20240229", "claude-3-opus-20240229"],
        "groq": ["qwen-qwq-32b", "llama3-70b-8192", "mixtral-8x7b-32768"],
        "openai": ["gpt-4o-mini", "gpt-4o", "o3-mini"]
    ]

    // State for currently selected provider, model, temperature, and API keys for each phase
    @State private var selectedProviders: [Phase: String] = [:]
    @State private var selectedModels: [Phase: String] = [:]
    @State private var selectedTemperatures: [Phase: Double] = [:]
    @State private var apiKeys: [String: String] = [:] // Store API keys by provider name

    // State for adding new custom model
    @State private var newModelProvider: String = "google" // Default provider selection
    @State private var newModelName: String = ""

    // Reset flag
    @State private var showResetAlert = false

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
                        // Provider Picker
                        Picker("Provider", selection: providerBinding(for: phase)) {
                            ForEach(providers, id: \.self) { provider in
                                Text(provider.capitalized).tag(provider)
                            }
                        }
                        .pickerStyle(.menu)

                        // Model Picker (dependent on selected provider, uses dynamic list)
                        Picker("Model", selection: modelBinding(for: phase)) {
                            if let provider = selectedProviders[phase],
                               let models = dynamicModelsByProvider[provider] { // Use dynamic list
                                ForEach(models, id: \.self) { model in
                                    Text(model).tag(model)
                                }
                            }
                        }
                        .pickerStyle(.menu)

                        // Temperature Slider
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Temperature")
                                Spacer()
                                Text(String(format: "%.2f", temperatureBinding(for: phase).wrappedValue))
                                    .foregroundColor(.secondary)
                            }

                            Slider(value: temperatureBinding(for: phase), in: 0...1, step: 0.01)
                        }
                    }
                }

                // Section for Adding Custom Models
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

                // Section for API Keys
                Section("API Keys") {
                    Text("Enter API keys for the selected providers. Keys are stored locally and sent with each request.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)

                    ForEach(providers, id: \.self) { provider in
                        SecureField("\(provider.capitalized) API Key", text: apiKeyBinding(for: provider))
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
                // Load custom models first
                loadCustomModels()

                // Load saved API keys from UserDefaults first
                for provider in providers {
                    if let savedKey = UserDefaults.standard.string(forKey: "apiKey_\(provider)") {
                        apiKeys[provider] = savedKey
                    }
                }

                // The thread should already have the correct configuration loaded
                // since we now load it in the ChoirThread initializer
                print("Using thread's existing model configuration")

                // Initialize view state from the (potentially loaded or default) thread configuration
                for phase in Phase.allCases {
                    if let config = thread.modelConfigs[phase] {
                        selectedProviders[phase] = config.provider
                        selectedModels[phase] = config.model
                        selectedTemperatures[phase] = config.temperature ?? 0.33
                        // Only load API keys from config if not already loaded from UserDefaults
                        if apiKeys["google"] == nil || apiKeys["google"]!.isEmpty { apiKeys["google"] = config.googleApiKey ?? "" }
                        if apiKeys["openai"] == nil || apiKeys["openai"]!.isEmpty { apiKeys["openai"] = config.openaiApiKey ?? "" }
                        if apiKeys["anthropic"] == nil || apiKeys["anthropic"]!.isEmpty { apiKeys["anthropic"] = config.anthropicApiKey ?? "" }
                        if apiKeys["mistral"] == nil || apiKeys["mistral"]!.isEmpty { apiKeys["mistral"] = config.mistralApiKey ?? "" }
                        if apiKeys["fireworks"] == nil || apiKeys["fireworks"]!.isEmpty { apiKeys["fireworks"] = config.fireworksApiKey ?? "" }
                        if apiKeys["cohere"] == nil || apiKeys["cohere"]!.isEmpty { apiKeys["cohere"] = config.cohereApiKey ?? "" }
                        if apiKeys["openrouter"] == nil || apiKeys["openrouter"]!.isEmpty { apiKeys["openrouter"] = config.openrouterApiKey ?? "" }
                        if apiKeys["groq"] == nil || apiKeys["groq"]!.isEmpty { apiKeys["groq"] = config.groqApiKey ?? "" }
                    }
                }
            }
            .alert("Reset to Defaults", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetToDefaults()
                }
            } message: {
                Text("This will reset all model configurations to their default values.")
            }
            // Autosave on any change to provider, model, or temperature selections
            .onChange(of: selectedProviders) { _, _ in
                saveChanges()
            }
            .onChange(of: selectedModels) { _, _ in
                saveChanges()
            }
            .onChange(of: selectedTemperatures) { _, _ in
                saveChanges()
            }
        }
    }

    // Create binding for provider selection
    private func providerBinding(for phase: Phase) -> Binding<String> {
        Binding<String>(
            get: { selectedProviders[phase] ?? thread.modelConfigs[phase]?.provider ?? "google" },
            set: { newValue in
                selectedProviders[phase] = newValue

                // When provider changes, set default model for that provider using dynamic list
                if let models = dynamicModelsByProvider[newValue], !models.isEmpty {
                    selectedModels[phase] = models[0]
                }
            }
        )
    }

    // Create binding for model selection
    private func modelBinding(for phase: Phase) -> Binding<String> {
        Binding<String>(
            get: { selectedModels[phase] ?? thread.modelConfigs[phase]?.model ?? "" },
            set: { selectedModels[phase] = $0 }
        )
    }

    // Create binding for temperature selection
    private func temperatureBinding(for phase: Phase) -> Binding<Double> {
        Binding<Double>(
            get: {
                selectedTemperatures[phase] ??
                thread.modelConfigs[phase]?.temperature ??
                0.33 // Default temperature
            },
            set: { selectedTemperatures[phase] = $0 }
        )
    }

    // Create binding for API key input
    private func apiKeyBinding(for provider: String) -> Binding<String> {
        Binding<String>(
            get: { apiKeys[provider] ?? "" },
            set: { apiKeys[provider] = $0 }
        )
    }

    // Load custom models from UserDefaults and merge with defaults
    private func loadCustomModels() {
        // Start with the default models
        var updatedModels = [
            "google": ["gemini-2.0-flash-lite", "gemini-2.0-flash", "gemini-2.5-pro-exp-03-25"],
            "openrouter": ["ai21/jamba-1.6-mini", "openrouter/quasar-alpha", "mistralai/mixtral-8x7b"],
            "anthropic": ["claude-3-haiku-20240307", "claude-3-sonnet-20240229", "claude-3-opus-20240229"],
            "groq": ["qwen-qwq-32b", "llama3-70b-8192", "mixtral-8x7b-32768"],
            "openai": ["gpt-4o-mini", "gpt-4o", "o3-mini"]
        ]

        for provider in providers {
            let key = "customModels_\(provider)"
            if let customModels = UserDefaults.standard.stringArray(forKey: key) {
                // Ensure provider exists in the dictionary
                if updatedModels[provider] == nil {
                    updatedModels[provider] = []
                }
                // Add custom models, avoiding duplicates
                for model in customModels {
                    if !(updatedModels[provider]?.contains(model) ?? false) {
                        updatedModels[provider]?.append(model)
                    }
                }
            }
        }
        // Update the state variable
        dynamicModelsByProvider = updatedModels
    }

    // Save custom model name to UserDefaults
    private func saveCustomModel() {
        let trimmedModelName = newModelName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedModelName.isEmpty else { return }

        let key = "customModels_\(newModelProvider)"
        var currentCustomModels = UserDefaults.standard.stringArray(forKey: key) ?? []

        if !currentCustomModels.contains(trimmedModelName) {
            currentCustomModels.append(trimmedModelName)
            UserDefaults.standard.set(currentCustomModels, forKey: key)
            print("Saved custom model '\(trimmedModelName)' for provider \(newModelProvider)")

            // Update the state to reflect the new model immediately
            loadCustomModels()

            // Clear the input field
            newModelName = ""
        } else {
            print("Custom model '\(trimmedModelName)' already exists for provider \(newModelProvider)")
        }
    }

    // Save changes to thread
    private func saveChanges() {
        for phase in Phase.allCases {
            if let provider = selectedProviders[phase],
               let model = selectedModels[phase] {
                let temperature = selectedTemperatures[phase]

                // Create new ModelConfig including API keys
                let newConfig = ModelConfig(
                    provider: provider,
                    model: model,
                    temperature: temperature,
                    openaiApiKey: apiKeys["openai"],
                    anthropicApiKey: apiKeys["anthropic"],
                    googleApiKey: apiKeys["google"],
                    mistralApiKey: apiKeys["mistral"],
                    fireworksApiKey: apiKeys["fireworks"],
                    cohereApiKey: apiKeys["cohere"],
                    openrouterApiKey: apiKeys["openrouter"],
                    groqApiKey: apiKeys["groq"]
                )

                // Update the thread's model config for this phase
                thread.modelConfigs[phase] = newConfig
                // Update the thread's model config for this phase
                thread.modelConfigs[phase] = newConfig
            }
        }

        // Save the entire active configuration globally to UserDefaults
        let globalConfigKey = "globalActiveModelConfig"
        if let encodedConfig = try? JSONEncoder().encode(thread.modelConfigs) {
            UserDefaults.standard.set(encodedConfig, forKey: globalConfigKey)
            print("Saved global active configuration")
        } else {
            print("Error encoding global active configuration")
        }

        // Save entered API keys to UserDefaults for testing
        for (provider, key) in apiKeys {
            if !key.isEmpty {
                UserDefaults.standard.set(key, forKey: "apiKey_\(provider)")
                print("Saved API key for \(provider) to UserDefaults")
            } else {
                // Remove key from UserDefaults if it's empty
                UserDefaults.standard.removeObject(forKey: "apiKey_\(provider)")
            }
        }
    }

    // Reset to defaults
    private func resetToDefaults() {
        let defaultConfigs: [Phase: ModelConfig] = [
            .action: ModelConfig(provider: "google", model: "gemini-2.0-flash-lite", temperature: 0.33),
            .experience: ModelConfig(provider: "openrouter", model: "ai21/jamba-1.6-mini", temperature: 0.33),
            .intention: ModelConfig(provider: "google", model: "gemini-2.0-flash", temperature: 0.33),
            .observation: ModelConfig(provider: "groq", model: "qwen-qwq-32b", temperature: 0.33),
            .understanding: ModelConfig(provider: "openrouter", model: "openrouter/quasar-alpha", temperature: 0.33),
            .yield: ModelConfig(provider: "google", model: "gemini-2.5-pro-exp-03-25", temperature: 0.33)
        ]

        // Update selected providers, models, and temperatures
        for phase in Phase.allCases {
            if let config = defaultConfigs[phase] {
                selectedProviders[phase] = config.provider
                selectedModels[phase] = config.model
                selectedTemperatures[phase] = config.temperature ?? 0.33
            }
        }

        // Clear API keys in the view state
        apiKeys.removeAll()

        // Update thread with defaults (which now include nil for API keys)
        thread.modelConfigs = defaultConfigs
    }
}

// Preview
#Preview {
    ModelConfigView(thread: ChoirThread())
}
