import SwiftUI
import SwiftData
import Charts

struct ConversationVisualizationView: View {
    let chat: Chat
    @State private var selectedVisualization = VisualizationType.emotions
    @State private var selectedEmotionCategories: Set<EmotionCategory> = Set(EmotionCategory.allCases)
    
    enum VisualizationType: String, CaseIterable {
        case emotions = "Emotional Trends"
        case temperatures = "Temperature Variations"
    }
    
    var body: some View {
        VStack {
            Picker("Visualization Type", selection: $selectedVisualization) {
                ForEach(VisualizationType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            if selectedVisualization == .emotions {
                EmotionCategoryFilter(selectedCategories: $selectedEmotionCategories)
                EmotionalTrendsChart(chat: chat, selectedCategories: selectedEmotionCategories)
            } else {
                TemperatureVariationChart(chat: chat)
            }
        }
        .navigationTitle("Conversation Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EmotionCategoryFilter: View {
    @Binding var selectedCategories: Set<EmotionCategory>
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(EmotionCategory.allCases, id: \.self) { category in
                    Toggle(category.rawValue, isOn: Binding(
                        get: { selectedCategories.contains(category) },
                        set: { isSelected in
                            if isSelected {
                                selectedCategories.insert(category)
                            } else {
                                selectedCategories.remove(category)
                            }
                        }
                    ))
                    .toggleStyle(.button)
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct EmotionalTrendsChart: View {
    let chat: Chat
    let selectedCategories: Set<EmotionCategory>
    
    struct EmotionDataPoint: Identifiable {
        let id = UUID()
        let timestamp: Date
        let emotion: String
        let percentage: Double
        let category: EmotionCategory
    }
    
    var emotionData: [EmotionDataPoint] {
        (chat.analyses ?? []).flatMap { analysis in
            (analysis.emotionalState ?? []).compactMap { emotion -> EmotionDataPoint? in
                guard let category = categorizeEmotion(emotion.emotion) else { return nil }
                return EmotionDataPoint(
                    timestamp: analysis.timestamp,
                    emotion: emotion.emotion,
                    percentage: emotion.percentage,
                    category: category
                )
            }
        }
        .filter { selectedCategories.contains($0.category) }
    }
    
    var body: some View {
        Chart(emotionData) { dataPoint in
            LineMark(
                x: .value("Time", dataPoint.timestamp),
                y: .value("Percentage", dataPoint.percentage)
            )
            .foregroundStyle(by: .value("Emotion", dataPoint.emotion))
            
            PointMark(
                x: .value("Time", dataPoint.timestamp),
                y: .value("Percentage", dataPoint.percentage)
            )
            .foregroundStyle(by: .value("Emotion", dataPoint.emotion))
        }
        .chartLegend(position: .bottom, alignment: .center)
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date.formatted(date: .omitted, time: .shortened))
                    }
                }
            }
        }
        .frame(height: 300)
        .padding()
    }
    
    private func categorizeEmotion(_ emotion: String) -> EmotionCategory? {
        return EmotionCategory.categorize(emotion)
    }
}

struct TemperatureVariationChart: View {
    let chat: Chat
    
    struct TemperatureDataPoint: Identifiable {
        let id = UUID()
        let timestamp: Date
        let agentType: AgentType
        let temperature: Double
        let effectiveness: Double
    }
    
    var temperatureData: [TemperatureDataPoint] {
        (chat.analyses ?? []).flatMap { analysis in
            [
                TemperatureDataPoint(
                    timestamp: analysis.timestamp,
                    agentType: .cortex,
                    temperature: analysis.nextTemperatures.cortex,
                    effectiveness: calculateEffectiveness(analysis.nextTemperatures.cortex, for: .cortex)
                ),
                TemperatureDataPoint(
                    timestamp: analysis.timestamp,
                    agentType: .seer,
                    temperature: analysis.nextTemperatures.seer,
                    effectiveness: calculateEffectiveness(analysis.nextTemperatures.seer, for: .seer)
                ),
                TemperatureDataPoint(
                    timestamp: analysis.timestamp,
                    agentType: .oracle,
                    temperature: analysis.nextTemperatures.oracle,
                    effectiveness: calculateEffectiveness(analysis.nextTemperatures.oracle, for: .oracle)
                ),
                TemperatureDataPoint(
                    timestamp: analysis.timestamp,
                    agentType: .house,
                    temperature: analysis.nextTemperatures.house,
                    effectiveness: calculateEffectiveness(analysis.nextTemperatures.house, for: .house)
                ),
                TemperatureDataPoint(
                    timestamp: analysis.timestamp,
                    agentType: .prudence,
                    temperature: analysis.nextTemperatures.prudence,
                    effectiveness: calculateEffectiveness(analysis.nextTemperatures.prudence, for: .prudence)
                ),
                TemperatureDataPoint(
                    timestamp: analysis.timestamp,
                    agentType: .conscience,
                    temperature: analysis.nextTemperatures.conscience,
                    effectiveness: calculateEffectiveness(analysis.nextTemperatures.conscience, for: .conscience)
                )
            ]
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("Temperature Settings")
                    .font(.headline)
                Chart(temperatureData) { dataPoint in
                    LineMark(
                        x: .value("Time", dataPoint.timestamp),
                        y: .value("Temperature", dataPoint.temperature)
                    )
                    .foregroundStyle(by: .value("Agent", dataPoint.agentType.rawValue))
                    
                    PointMark(
                        x: .value("Time", dataPoint.timestamp),
                        y: .value("Temperature", dataPoint.temperature)
                    )
                    .foregroundStyle(by: .value("Agent", dataPoint.agentType.rawValue))
                }
                .chartLegend(position: .bottom, alignment: .center)
                .chartYScale(domain: 0...1)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date.formatted(date: .omitted, time: .shortened))
                            }
                        }
                    }
                }
            }
            .frame(height: 200)
            
            VStack(alignment: .leading) {
                Text("Effectiveness Ratings")
                    .font(.headline)
                Chart(temperatureData) { dataPoint in
                    LineMark(
                        x: .value("Time", dataPoint.timestamp),
                        y: .value("Effectiveness", dataPoint.effectiveness)
                    )
                    .foregroundStyle(by: .value("Agent", dataPoint.agentType.rawValue))
                    
                    PointMark(
                        x: .value("Time", dataPoint.timestamp),
                        y: .value("Effectiveness", dataPoint.effectiveness)
                    )
                    .foregroundStyle(by: .value("Agent", dataPoint.agentType.rawValue))
                }
                .chartLegend(position: .bottom, alignment: .center)
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date.formatted(date: .omitted, time: .shortened))
                            }
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
    }
    
    private func calculateEffectiveness(_ temperature: Double, for agentType: AgentType) -> Double {
        let optimalRanges: [AgentType: (min: Double, max: Double)] = [
            .cortex: (0.5, 0.7),     // Balanced emotional processing
            .seer: (0.2, 0.4),       // Clear pattern recognition
            .oracle: (0.3, 0.5),     // Strategic thinking
            .house: (0.3, 0.5),      // Practical implementation
            .prudence: (0.2, 0.4),   // Risk assessment
            .conscience: (0.4, 0.6)   // Moral judgment
        ]
        
        guard let range = optimalRanges[agentType] else { return 0 }
        
        if temperature >= range.min && temperature <= range.max {
            return 100.0
        }
        
        let distanceFromOptimal = temperature < range.min 
            ? range.min - temperature 
            : temperature - range.max
            
        return max(0, 100 - (distanceFromOptimal * 200))
    }
}

@MainActor
private func createPreviewContainer() -> (ModelContainer, Chat) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Chat.self, ChatMessage.self, ChatAnalysis.self,
            AgentResponse.self, EmotionMeasurement.self,
            AgentSettings.self, AISettings.self,
        configurations: config
    )
    
    // Create a sample chat
    let chat = Chat(title: "Preview Chat")
    container.mainContext.insert(chat)
    chat.messages = []
    chat.analyses = []
    
    // Create messages
    let message = ChatMessage(content: "How can I stay motivated?", role: .user)
    container.mainContext.insert(message)
    message.chat = chat
    chat.messages?.append(message)
    
    // Create analyses with emotional states and temperatures
    let timestamps = [
        Date().addingTimeInterval(-3600),  // 1 hour ago
        Date().addingTimeInterval(-1800),  // 30 minutes ago
        Date()                             // Now
    ]
    
    for timestamp in timestamps {
        let analysis = ChatAnalysis(
            timestamp: timestamp,
            userMessageId: message.id,
            userInput: message.content,
            finalResponse: "Response at \(timestamp.formatted())",
            nextTemperatures: TemperatureSettings(
                cortex: Double.random(in: 0.4...0.8),
                seer: Double.random(in: 0.2...0.6),
                oracle: Double.random(in: 0.3...0.7),
                house: Double.random(in: 0.3...0.7),
                prudence: Double.random(in: 0.2...0.6),
                conscience: Double.random(in: 0.3...0.7)
            )
        )
        container.mainContext.insert(analysis)
        analysis.chat = chat
        chat.analyses?.append(analysis)
        
        // Add emotions
        let emotions = [
            ("Joy", Double.random(in: 20...80)),
            ("Curiosity", Double.random(in: 30...90)),
            ("Confidence", Double.random(in: 40...70)),
            ("Focus", Double.random(in: 50...100))
        ]
        
        analysis.emotionalState = []
        for (emotion, percentage) in emotions {
            let measurement = EmotionMeasurement(emotion: emotion, percentage: percentage)
            container.mainContext.insert(measurement)
            measurement.analysis = analysis
            analysis.emotionalState?.append(measurement)
        }
    }
    
    try? container.mainContext.save()
    return (container, chat)
}

#Preview {
    @MainActor in
    let (container, chat) = createPreviewContainer()
    NavigationStack {
        ConversationVisualizationView(chat: chat)
            .modelContainer(container)
    }
} 