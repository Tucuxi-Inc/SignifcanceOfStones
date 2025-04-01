import SwiftUI
import SwiftData

struct AgentSettingsView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Query private var aiSettings: [AISettings]  // Change to query AISettings
    @Query(sort: \Chat.timestamp, order: .reverse) private var chats: [Chat]
    
    private var currentChat: Chat? {
        chats.first
    }
    
    private var orderedAgentTypes: [AgentType] = [
        .cortex,   // 1. Basic cognition
        .seer,     // 2. Pattern recognition
        .oracle,   // 3. Strategic thinking
        .house,    // 4. Implementation
        .prudence, // 5. Risk assessment
        .conscience // 6. Moral judgment
    ]
    
    private var sortedAgentSettings: [AgentSettings] {
        guard let settings = aiSettings.first?.agentSettings else { return [] }
        return orderedAgentTypes.compactMap { agentType in
            settings.first { $0.agentType == agentType }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Group {
                    Section("Analysis") {
                        NavigationLink {
                            AgentResponsesView()
                        } label: {
                            Label("View Agent Responses", systemImage: "text.bubble")
                        }
                        
                        NavigationLink {
                            EmotionalStateView()  // Shows current emotional state
                        } label: {
                            Label("Emotional State", systemImage: "heart.text.square")
                        }
                    }
                    
                    Section("Processing") {
                        NavigationLink {
                            EmotionalStateSettingsView()  // For adjusting emotional settings
                        } label: {
                            Label("Emotional State Settings", systemImage: "slider.horizontal.3")
                        }
                    }
                    
                    Section("Processing Agents") {
                        ForEach(sortedAgentSettings) { settings in
                            AgentSettingCell(settings: settings)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
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

struct AgentSettingCell: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var settings: AgentSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(settings.agentType.rawValue)
                    .font(.headline)
                Spacer()
                Toggle("Enabled", isOn: $settings.isEnabled)
                    .labelsHidden()
                    .onChange(of: settings.isEnabled) { _, _ in
                        try? modelContext.save()
                    }
            }
            
            if settings.isEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Menu {
                        ForEach(AISettings.Model.availableModels, id: \.self) { model in
                            Button(model) {
                                settings.model = model
                                try? modelContext.save()
                            }
                        }
                    } label: {
                        HStack {
                            Text("Model: \(settings.model)")
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .padding(.vertical, 4)
                    }
                    
                    HStack {
                        Text("Temperature: \(String(format: "%.2f", settings.temperature))")
                        Slider(value: $settings.temperature, in: 0...1)
                            .onChange(of: settings.temperature) { _, _ in
                                try? modelContext.save()
                            }
                    }
                }
            }
            
            Text(settings.agentType.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .onAppear {
            if !AISettings.Model.availableModels.contains(settings.model) {
                settings.model = AISettings.Model.defaultModel
                try? modelContext.save()
            }
        }
    }
}

struct EmotionalStateView: View {
    @Query private var aiSettings: [AISettings]  // Change to query AISettings
    
    var emotionalState: String {
        guard let settings = aiSettings.first?.agentSettings else { return "Unknown" }
        
        // Check if all temperatures are at baseline
        let allBaseline = settings.allSatisfy { agentSettings in
            agentSettings.temperature == agentSettings.agentType.defaultTemperature
        }
        
        if allBaseline {
            return "Baseline"
        }
        // TODO: Add logic for other emotional states based on temperature variations
        return "Custom"
    }
    
    var stateDescription: String {
        switch emotionalState {
        case "Baseline":
            return "The system is operating at its default balanced state, with all agents using their recommended baseline temperatures. This promotes balanced and measured responses across all cognitive functions."
        // Add other state descriptions as needed
        default:
            return "The system is operating with custom temperature settings, which may emphasize certain cognitive aspects over others."
        }
    }
    
    var body: some View {
        List {
            Section("Current State") {
                Text(emotionalState)
                    .font(.headline)
            }
            
            Section("Description") {
                Text(stateDescription)
            }
        }
        .navigationTitle("System State")
        .navigationBarTitleDisplayMode(.inline)
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
        apiKey: APIConfig.openAIKey,  // Use actual API key
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
        AgentSettingsView()
            .modelContainer(createPreviewContainer())
    }
}