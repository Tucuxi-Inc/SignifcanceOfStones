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
        .dayDream, // 6. Creative associations
        .conscience // 7. Moral judgment
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
    @Query private var aiSettings: [AISettings]
    
    private var orderedAgentTypes: [AgentType] = [
        .cortex,   // 1. Basic cognition
        .seer,     // 2. Pattern recognition
        .oracle,   // 3. Strategic thinking
        .house,    // 4. Implementation
        .prudence, // 5. Risk assessment
        .dayDream, // 6. Creative associations
        .conscience // 7. Moral judgment
    ]
    
    var emotionalState: String {
        guard let settings = aiSettings.first?.agentSettings else { return "Unknown" }
        
        // Check if all temperatures are at baseline
        let allBaseline = settings.allSatisfy { agentSettings in
            abs(agentSettings.temperature - agentSettings.agentType.defaultTemperature) < 0.1
        }
        
        if allBaseline {
            return "Baseline Balance"
        }
        
        // Check emphasis patterns
        let cortexSetting = settings.first(where: { $0.agentType == .cortex })
        let seerSetting = settings.first(where: { $0.agentType == .seer })
        let oracleSetting = settings.first(where: { $0.agentType == .oracle })
        let dayDreamSetting = settings.first(where: { $0.agentType == .dayDream })
        
        // Determine emotional/cognitive emphasis
        if let cortex = cortexSetting, let dayDream = dayDreamSetting, 
           cortex.temperature > cortex.agentType.defaultTemperature + 0.2 &&
           dayDream.temperature > dayDream.agentType.defaultTemperature + 0.2 {
            return "Emotionally Creative"
        }
        
        if let seer = seerSetting, let oracle = oracleSetting,
           seer.temperature > seer.agentType.defaultTemperature + 0.2 &&
           oracle.temperature > oracle.agentType.defaultTemperature + 0.2 {
            return "Analytically Forward-Looking"
        }
        
        if let dayDream = dayDreamSetting, 
           dayDream.temperature > dayDream.agentType.defaultTemperature + 0.3 {
            return "Highly Creative"
        }
        
        if let cortex = cortexSetting, 
           cortex.temperature > cortex.agentType.defaultTemperature + 0.3 {
            return "Emotionally Expressive"
        }
        
        // Default custom state
        return "Custom Balance"
    }
    
    var stateDescription: String {
        switch emotionalState {
        case "Baseline Balance":
            return "The system is operating at its default balanced state, with all agents using their recommended baseline temperatures. This promotes even, measured responses across all cognitive functions."
        case "Emotionally Creative":
            return "The system is operating with higher temperatures for both emotional processing and creative associations. This emphasizes emotional insight and novel connections, potentially producing more expressive and imaginative responses."
        case "Analytically Forward-Looking":
            return "The system is operating with higher temperatures for pattern recognition and strategic thinking. This emphasizes analytical depth and future planning, potentially producing more insightful and strategic responses."
        case "Highly Creative":
            return "The system is operating with significantly elevated creative processing. This emphasizes novel connections, metaphorical thinking, and divergent idea generation, potentially producing more imaginative and unconventional responses."
        case "Emotionally Expressive":
            return "The system is operating with significantly elevated emotional processing. This emphasizes emotional depth and nuance, potentially producing more empathetic and emotionally resonant responses."
        default:
            return "The system is operating with custom temperature settings that emphasize certain cognitive aspects over others, creating a unique cognitive balance."
        }
    }
    
    private func temperatureDeviation(_ temperature: Double, defaultTemp: Double) -> (String, Color) {
        let diff = temperature - defaultTemp
        if abs(diff) < 0.1 {
            return ("Balanced", .gray)
        } else if diff > 0.3 {
            return ("Much Higher", .red)
        } else if diff > 0.1 {
            return ("Higher", .orange)
        } else if diff < -0.3 {
            return ("Much Lower", .blue)
        } else {
            return ("Lower", .indigo)
        }
    }
    
    private func cognitiveMeaning(for agentType: AgentType, temperature: Double) -> String {
        let defaultTemp = agentType.defaultTemperature
        let diff = temperature - defaultTemp
        
        if abs(diff) < 0.1 {
            return "Balanced processing"
        }
        
        switch agentType {
        case .cortex:
            return diff > 0 ? "Increased emotional expression" : "Increased emotional restraint"
        case .seer:
            return diff > 0 ? "Enhanced pattern recognition" : "More focused pattern recognition"
        case .oracle:
            return diff > 0 ? "More creative strategic planning" : "More conservative strategic planning"
        case .house:
            return diff > 0 ? "More flexible implementation" : "More structured implementation"
        case .prudence:
            return diff > 0 ? "Less risk aversion" : "Increased risk aversion"
        case .dayDream:
            return diff > 0 ? "Heightened creative associations" : "More focused creative connections"
        case .conscience:
            return diff > 0 ? "More nuanced ethical consideration" : "More principled ethical consideration"
        }
    }
    
    var body: some View {
        List {
            Section("Current Cognitive State") {
                Text(emotionalState)
                    .font(.headline)
                
                Text(stateDescription)
                    .padding(.vertical, 4)
            }
            
            Section("Agent Temperature Analysis") {
                if let agents = aiSettings.first?.agentSettings {
                    ForEach(orderedAgentTypes, id: \.self) { agentType in
                        if let agent = agents.first(where: { $0.agentType == agentType }) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(agent.agentType.rawValue)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    // Show default and current temps
                                    Text("\(String(format: "%.2f", agent.temperature)) / \(String(format: "%.2f", agent.agentType.defaultTemperature))")
                                        .font(.subheadline.monospaced())
                                }
                                
                                HStack {
                                    // Temperature deviation indicators
                                    let (label, color) = temperatureDeviation(agent.temperature, defaultTemp: agent.agentType.defaultTemperature)
                                    Text(label)
                                        .font(.caption)
                                        .foregroundColor(color)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(color.opacity(0.2))
                                        .cornerRadius(4)
                                    
                                    Spacer()
                                    
                                    // Show deviation graphically
                                    TemperatureDeviationBar(
                                        current: agent.temperature,
                                        baseline: agent.agentType.defaultTemperature
                                    )
                                    .frame(width: 100, height: 12)
                                }
                                
                                // Cognitive effect
                                Text(cognitiveMeaning(for: agent.agentType, temperature: agent.temperature))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            
            Section("System Implications") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current cognitive emphasis may affect:")
                        .font(.subheadline)
                    
                    let effects = getCognitiveEffects()
                    ForEach(effects, id: \.self) { effect in
                        HStack(alignment: .top) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .padding(.top, 6)
                            Text(effect)
                                .font(.callout)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("System Cognitive State")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func getCognitiveEffects() -> [String] {
        guard let agents = aiSettings.first?.agentSettings else { 
            return ["Unknown system state"] 
        }
        
        var effects = [String]()
        
        // Check for specific combinations
        let dayDreamSetting = agents.first(where: { $0.agentType == .dayDream })
        let cortexSetting = agents.first(where: { $0.agentType == .cortex })
        let prudenceSetting = agents.first(where: { $0.agentType == .prudence })
        
        if let dayDream = dayDreamSetting, 
           dayDream.temperature > dayDream.agentType.defaultTemperature + 0.2 {
            effects.append("Responses may include more metaphors and creative connections")
            effects.append("Novel perspectives and unconventional ideas are more likely")
        }
        
        if let cortex = cortexSetting,
           cortex.temperature > cortex.agentType.defaultTemperature + 0.2 {
            effects.append("Responses may show more emotional depth and nuance")
            effects.append("Emotional aspects of queries will receive more focus")
        }
        
        if let prudence = prudenceSetting,
           prudence.temperature < prudence.agentType.defaultTemperature - 0.1 {
            effects.append("Responses may be more cautious and risk-aware")
            effects.append("Potential downsides will be more thoroughly analyzed")
        }
        
        if effects.isEmpty {
            effects.append("Balanced cognitive functioning across all domains")
            effects.append("No single cognitive aspect is significantly emphasized")
        }
        
        return effects
    }
}

// Visual bar showing temperature deviation from baseline
struct TemperatureDeviationBar: View {
    let current: Double
    let baseline: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))
                
                // Center line (baseline)
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 2, height: geometry.size.height)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                
                // Current value indicator
                let maxDeviation = 0.5 // Maximum expected deviation
                let normalizedDeviation = (current - baseline) / maxDeviation
                let cappedDeviation = min(max(normalizedDeviation, -1), 1)
                let width = geometry.size.width
                
                // Position from center based on deviation
                let xPosition = width/2 + (width/2 * cappedDeviation)
                
                Circle()
                    .fill(normalizedDeviation > 0 ? Color.orange : Color.blue)
                    .frame(width: 8, height: 8)
                    .position(x: xPosition, y: geometry.size.height/2)
            }
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
        .dayDream, // 6. Creative associations
        .conscience // 7. Moral judgment
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