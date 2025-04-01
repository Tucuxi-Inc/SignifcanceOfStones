import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var agentSettings: [AgentSettings]
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            MindChatView(modelContext: modelContext)
                .onAppear {
                    if agentSettings.isEmpty {  // Only create settings if none exist
                        createDefaultAgentSettings()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                        }
                    }
                }
        }
        .sheet(isPresented: $showingSettings) {
            AgentSettingsView()  // Changed from SettingsView
        }
    }
    
    private func createDefaultAgentSettings() {
        // First create AISettings
        let apiKey = APIConfig.openAIKey
        guard !apiKey.isEmpty else {
            print("Error: OpenAI API key is not configured")
            return
        }
        
        let aiSettings = AISettings(
            model: AISettings.Model.defaultModel,
            apiKey: apiKey,
            defaultTemperature: 0.7,
            debugMode: true,
            logResponses: true
        )
        modelContext.insert(aiSettings)
        
        // Initialize agentSettings array if nil
        if aiSettings.agentSettings == nil {
            aiSettings.agentSettings = []
        }
        
        let orderedTypes: [AgentType] = [
            .cortex,   // 1. Basic cognition
            .seer,     // 2. Pattern recognition
            .oracle,   // 3. Strategic thinking
            .house,    // 4. Implementation
            .prudence, // 5. Risk assessment
            .conscience // 6. Moral judgment
        ]
        
        // Create and add settings with inverse relationships
        for agentType in orderedTypes {
            let settings = AgentSettings(
                agentType: agentType,
                model: AISettings.Model.defaultModel,
                temperature: agentType.defaultTemperature
            )
            modelContext.insert(settings)
            settings.aiSettings = aiSettings  // Set inverse relationship
            aiSettings.agentSettings?.append(settings)  // Add to array
        }
        
        try? modelContext.save()
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
    
    // Create AISettings with actual API key
    let aiSettings = AISettings(
        model: AISettings.Model.defaultModel,
        apiKey: APIConfig.openAIKey,  // Use the actual API key
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
    ContentView()
        .modelContainer(createPreviewContainer())
} 
