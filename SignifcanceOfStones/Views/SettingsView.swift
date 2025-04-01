import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var aiSettings: [AISettings]
    @Environment(\.dismiss) private var dismiss
    
    private let availableModels = AISettings.Model.availableModels
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(aiSettings.first?.agentSettings ?? []) { agentSettings in
                    AgentSettingsRow(settings: agentSettings, availableModels: availableModels)
                }
                
                Section("Analysis") {
                    NavigationLink("View Agent Responses") {
                        AgentResponsesView()
                    }
                }
                
                Section(header: Text("Processing")) {
                    NavigationLink(destination: EmotionalStateSettingsView()) {
                        HStack {
                            Label("Emotional State", systemImage: "brain")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetToDefaults()
                    }
                }
            }
        }
    }
    
    private func resetToDefaults() {
        guard let settings = aiSettings.first?.agentSettings else { return }
        
        for agentSettings in settings {
            agentSettings.model = AISettings.Model.defaultModel
            agentSettings.temperature = agentSettings.agentType.defaultTemperature
            agentSettings.isEnabled = true
        }
        try? modelContext.save()
    }
}

struct AgentSettingsRow: View {
    @Bindable var settings: AgentSettings
    let availableModels: [String]
    
    var body: some View {
        Section(settings.agentType.rawValue) {
            Toggle("Enabled", isOn: $settings.isEnabled)
            
            Picker("Model", selection: $settings.model) {
                ForEach(availableModels, id: \.self) { model in
                    Text(model).tag(model)
                }
            }
            
            VStack(alignment: .leading) {
                Text("Temperature: \(settings.temperature, specifier: "%.2f")")
                Slider(value: $settings.temperature, in: 0...1)
            }
            
            Text(settings.agentType.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

@MainActor
private func createPreviewContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Chat.self, ChatMessage.self, ChatAnalysis.self,
            AgentResponse.self, EmotionMeasurement.self,
            AgentSettings.self, AISettings.self,
        configurations: config
    )
    
    // Create AISettings
    let aiSettings = AISettings(
        model: AISettings.Model.defaultModel,
        apiKey: APIConfig.openAIKey,
        defaultTemperature: 0.7,
        debugMode: true,
        logResponses: true
    )
    container.mainContext.insert(aiSettings)
    aiSettings.agentSettings = []
    
    // Create agent settings
    let orderedTypes: [AgentType] = [
        .cortex,   // 1. Basic cognition
        .seer,     // 2. Pattern recognition
        .oracle,   // 3. Strategic thinking
        .house,    // 4. Implementation
        .prudence, // 5. Risk assessment
        .conscience // 6. Moral judgment
    ]
    
    for agentType in orderedTypes {
        let settings = AgentSettings(
            agentType: agentType,
            model: AISettings.Model.defaultModel,
            temperature: agentType.defaultTemperature
        )
        container.mainContext.insert(settings)
        settings.aiSettings = aiSettings
        aiSettings.agentSettings?.append(settings)
    }
    
    try? container.mainContext.save()
    return container
}

#Preview {
    @MainActor in
    NavigationStack {
        SettingsView()
            .modelContainer(createPreviewContainer())
    }
} 