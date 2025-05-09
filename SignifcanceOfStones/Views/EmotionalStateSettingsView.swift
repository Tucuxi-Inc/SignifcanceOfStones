import SwiftUI
import SwiftData

struct EmotionalStateSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var agentSettings: [AgentSettings]
    @StateObject private var emotionalState = EmotionalStateManager()
    @State private var showingPresets = false
    
    // Common emotional presets
    let emotionalPresets: [(name: String, emotions: [(String, Double)])] = [
        ("Balanced Learning", [("curiosity", 40.0), ("focus", 30.0), ("serenity", 30.0)]),
        ("Creative Problem Solving", [("creative", 40.0), ("analytical", 30.0), ("determination", 30.0)]),
        ("Critical Analysis", [("analytical", 50.0), ("critical", 30.0), ("clarity", 20.0)]),
        ("Empathetic Understanding", [("empathetic", 40.0), ("intuitive", 30.0), ("mindful", 30.0)]),
        ("Careful Consideration", [("contemplative", 40.0), ("systematic", 30.0), ("prudence", 30.0)])
    ]
    
    var body: some View {
        Form {
            // Emotion Selection Section
            Section(header: Text("Emotion Selection")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose an emotion to configure agent temperatures")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Category Picker
                    HStack {
                        Text("Category:")
                            .foregroundColor(.secondary)
                        Picker("", selection: $emotionalState.selectedCategory) {
                            ForEach(EmotionCategory.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // Updated Emotion Picker
                    HStack {
                        Text("Emotion:")
                            .foregroundColor(.secondary)
                        Picker("", selection: $emotionalState.selectedEmotion) {
                            Text("None").tag(String?.none)
                            Divider()
                            ForEach(emotionalState.selectedCategory.emotions, id: \.self) { emotion in
                                Text(emotion).tag(Optional(emotion))
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: emotionalState.selectedEmotion) { _, newEmotion in
                            if let emotion = newEmotion {
                                let temps = EmotionalTemperature.getEmotionTemperatures(emotion)
                                emotionalState.currentTemperatures = EmotionalTemperatures(from: temps)
                                updateAgentSettings()
                            }
                        }
                    }
                }
            }
            
            // Baseline Toggle Section
            Section {
                Toggle("Use Baseline Settings", isOn: $emotionalState.isUsingBaseline)
                    .onChange(of: emotionalState.isUsingBaseline) { oldValue, newValue in
                        if newValue {
                            emotionalState.resetToBaseline()
                        }
                    }
                
                if emotionalState.isUsingBaseline {
                    Text("Using balanced baseline temperatures for all agents")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Updated Preset Section
            Section(header: Text("Emotional Presets")) {
                ForEach(emotionalPresets, id: \.name) { preset in
                    Button(action: {
                        emotionalState.setEmotionalBlend(preset.emotions)
                        let temps = EmotionalTemperature.calculateBlendedTemperatures(preset.emotions)
                        emotionalState.currentTemperatures = EmotionalTemperatures(from: temps)
                        emotionalState.selectedEmotion = nil
                        updateAgentSettings()
                    }) {
                        VStack(alignment: .leading) {
                            Text(preset.name)
                                .font(.headline)
                            Text(preset.emotions.map { "\($0.0) (\(Int($0.1))%)" }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Updated Current Processing Temperatures Section
            Section(header: Text("Current Processing Temperatures")) {
                ForEach(AgentType.allCases) { agent in
                    EmotionalTemperatureRow(
                        agent: agent,
                        value: getTemperatureValue(for: agent)
                    )
                }
            }
            .onChange(of: emotionalState.currentTemperatures) { _, _ in
                updateAgentSettings()
            }
            
            // Updated Processing Impact Section
            Section(header: Text("Processing Impact")) {
                if let emotion = emotionalState.selectedEmotion {
                    // Show impact for single emotion
                    ProcessingImpactView(emotion: emotion, emotionalState: emotionalState)
                } else if !emotionalState.isUsingBaseline {
                    // Show impact for preset or blended emotions
                    ProcessingImpactView(emotion: "Current Blend", emotionalState: emotionalState)
                }
            }
            
            // Updated Reset Section
            Section {
                Button("Reset to Baseline") {
                    emotionalState.resetToBaseline()
                    emotionalState.selectedEmotion = nil
                    updateAgentSettings()
                }
            }
        }
        .onAppear {
            // Initialize with current agent settings
            let tuple = (
                cortex: agentSettings.first(where: { $0.agentType == .cortex })?.temperature ?? EmotionalTemperature.baselineTemperatures.cortex,
                seer: agentSettings.first(where: { $0.agentType == .seer })?.temperature ?? EmotionalTemperature.baselineTemperatures.seer,
                oracle: agentSettings.first(where: { $0.agentType == .oracle })?.temperature ?? EmotionalTemperature.baselineTemperatures.oracle,
                house: agentSettings.first(where: { $0.agentType == .house })?.temperature ?? EmotionalTemperature.baselineTemperatures.house,
                prudence: agentSettings.first(where: { $0.agentType == .prudence })?.temperature ?? EmotionalTemperature.baselineTemperatures.prudence,
                dayDream: agentSettings.first(where: { $0.agentType == .dayDream })?.temperature ?? EmotionalTemperature.baselineTemperatures.dayDream,
                conscience: agentSettings.first(where: { $0.agentType == .conscience })?.temperature ?? EmotionalTemperature.baselineTemperatures.conscience
            )
            emotionalState.currentTemperatures = EmotionalTemperatures(from: tuple)
        }
    }
    
    private func getTemperatureValue(for agent: AgentType) -> Double {
        let temps = emotionalState.currentTemperatures
        switch agent {
        case .cortex: return temps.cortex
        case .seer: return temps.seer
        case .oracle: return temps.oracle
        case .house: return temps.house
        case .prudence: return temps.prudence
        case .dayDream: return temps.dayDream
        case .conscience: return temps.conscience
        }
    }
    
    private func updateAgentSettings() {
        for agent in AgentType.allCases {
            if let settings = agentSettings.first(where: { $0.agentType == agent }) {
                settings.temperature = EmotionalTemperature.getValue(for: agent, from: emotionalState.currentTemperatures)
            }
        }
        try? modelContext.save()
    }
}

struct EmotionalTemperatureRow: View {
    let agent: AgentType
    let value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(agent.icon + " " + agent.name)
                Spacer()
                Text(String(format: "%.2f", value))
                    .foregroundColor(.secondary)
            }
            
            TemperatureBar(value: value)
                .frame(height: 8)
                .cornerRadius(4)
            
            Text(agent.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct TemperatureBar: View {
    let value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                
                Rectangle()
                    .fill(temperatureColor)
                    .frame(width: geometry.size.width * CGFloat(value))
            }
        }
    }
    
    var temperatureColor: Color {
        switch value {
        case 0.0...0.3: return .red
        case 0.3...0.5: return .orange
        case 0.5...0.7: return .green
        case 0.7...0.8: return .blue
        case 0.8...1.0: return .purple
        default: return .gray
        }
    }
}

struct ProcessingImpactView: View {
    let emotion: String
    let emotionalState: EmotionalStateManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This emotional state affects processing by:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ForEach(getProcessingImpacts(), id: \.0) { impact in
                HStack(alignment: .top) {
                    Text(impact.0)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    
                    Text(impact.1)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func getProcessingImpacts() -> [(String, String)] {
        let temps = emotionalState.currentTemperatures
        return [
            ("Cortex", getImpactDescription(for: AgentType.cortex, value: temps.cortex)),
            ("Seer", getImpactDescription(for: AgentType.seer, value: temps.seer)),
            ("Oracle", getImpactDescription(for: AgentType.oracle, value: temps.oracle)),
            ("House", getImpactDescription(for: AgentType.house, value: temps.house)),
            ("Prudence", getImpactDescription(for: AgentType.prudence, value: temps.prudence)),
            ("Day-Dream", getImpactDescription(for: AgentType.dayDream, value: temps.dayDream)),
            ("Conscience", getImpactDescription(for: AgentType.conscience, value: temps.conscience))
        ]
    }
    
    private func getImpactDescription(for agent: AgentType, value: Double) -> String {
        switch value {
        case 0.0...0.3:
            return "Very conservative/cautious processing"
        case 0.3...0.5:
            return "Measured/careful processing"
        case 0.5...0.7:
            return "Balanced/moderate processing"
        case 0.7...0.8:
            return "Enhanced/exploratory processing"
        case 0.8...1.0:
            return "Maximum creative/exploratory processing"
        default:
            return "Invalid temperature value"
        }
    }
} 