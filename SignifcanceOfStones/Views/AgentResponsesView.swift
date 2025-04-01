import SwiftUI
import SwiftData

struct AgentResponsesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Chat.timestamp, order: .reverse) private var chats: [Chat]
    
    var body: some View {
        NavigationStack {
            List(chats) { chat in
                NavigationLink {
                    ChatAnalysisListView(chat: chat)
                } label: {
                    VStack(alignment: .leading) {
                        Text(chat.title)
                            .font(.headline)
                        Text(chat.timestamp.formatted())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Chats")
        }
    }
}

struct ChatAnalysisListView: View {
    let chat: Chat
    
    var body: some View {
        List {
            Section {
                NavigationLink {
                    ConversationVisualizationView(chat: chat)
                } label: {
                    Label("View Conversation Analysis", systemImage: "chart.xyaxis.line")
                }
            }
            
            Section("Prompts") {
                ForEach(chat.messages?.sorted(by: { $0.timestamp < $1.timestamp })
                    .filter { $0.role == .user } ?? []) { message in
                        if let analysis = findAnalysis(for: message) {
                            NavigationLink {
                                AgentResponseDetailView(analysis: analysis)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(message.content)
                                        .lineLimit(2)
                                    Text(message.timestamp.formatted())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                }
            }
        }
        .navigationTitle("Chat Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func findAnalysis(for message: ChatMessage) -> ChatAnalysis? {
        return chat.analyses?.first { $0.userMessageId == message.id }
    }
}

struct AgentResponseDetailView: View {
    let analysis: ChatAnalysis
    
    var body: some View {
        List {
            Section("User Input") {
                Text(analysis.userInput)
                    .textSelection(.enabled)
            }
            
            Section("Agent Responses") {
                ForEach(analysis.agentResponses?.sorted(by: { $0.timestamp < $1.timestamp }) ?? []) { response in
                    DisclosureGroup {
                        Text(response.response)
                            .textSelection(.enabled)
                            .padding(.vertical, 8)
                    } label: {
                        HStack {
                            Label(
                                response.agentType.rawValue,
                                systemImage: iconFor(agentType: response.agentType)
                            )
                            Spacer()
                            Text(response.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section("Emotional Analysis") {
                ForEach(analysis.emotionalState ?? [], id: \.emotion) { emotion in
                    HStack {
                        Text(emotion.emotion)
                        Spacer()
                        Text("\(Int(emotion.percentage))%")
                    }
                }
            }
            
            Section("Temperature Settings") {
                TemperatureSettingsView(settings: analysis.nextTemperatures)
            }
            
            Section("Final Response") {
                Text(analysis.finalResponse)
                    .textSelection(.enabled)
            }
        }
        .navigationTitle("Analysis Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func iconFor(agentType: AgentType) -> String {
        switch agentType {
        case .cortex: return "brain.head.profile"
        case .seer: return "sparkles.tv"
        case .oracle: return "chart.line.uptrend.xyaxis"
        case .house: return "house"
        case .prudence: return "exclamationmark.shield"
        case .conscience: return "heart.circle"
        }
    }
}

struct TemperatureSettingsView: View {
    let settings: TemperatureSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TemperatureRow(label: "Cortex", value: settings.cortex)
            TemperatureRow(label: "Seer", value: settings.seer)
            TemperatureRow(label: "Oracle", value: settings.oracle)
            TemperatureRow(label: "House", value: settings.house)
            TemperatureRow(label: "Prudence", value: settings.prudence)
            TemperatureRow(label: "Conscience", value: settings.conscience)
        }
    }
}

struct TemperatureRow: View {
    let label: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(String(format: "%.2f", value))
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
    
    // Create analysis with agent responses
    let analysis = ChatAnalysis(
        userMessageId: message.id,
        userInput: message.content,
        finalResponse: "Here's a comprehensive response about motivation...",
        nextTemperatures: TemperatureSettings(
            cortex: 0.7,
            seer: 0.4,
            oracle: 0.5,
            house: 0.5,
            prudence: 0.3,
            conscience: 0.6
        )
    )
    container.mainContext.insert(analysis)
    analysis.chat = chat
    chat.analyses?.append(analysis)
    
    // Add agent responses
    let orderedTypes: [AgentType] = [
        .cortex,   // 1. Basic cognition
        .seer,     // 2. Pattern recognition
        .oracle,   // 3. Strategic thinking
        .house,    // 4. Implementation
        .prudence, // 5. Risk assessment
        .conscience // 6. Moral judgment
    ]
    
    analysis.agentResponses = []
    for agentType in orderedTypes {
        let response = AgentResponse(
            agentType: agentType,
            response: "Response from \(agentType.rawValue) about motivation..."
        )
        container.mainContext.insert(response)
        response.analysis = analysis
        analysis.agentResponses?.append(response)
    }
    
    // Add emotional measurements
    let emotions = [
        ("Joy", 65.0),
        ("Curiosity", 80.0),
        ("Confidence", 55.0),
        ("Focus", 75.0)
    ]
    
    analysis.emotionalState = []
    for (emotion, percentage) in emotions {
        let measurement = EmotionMeasurement(emotion: emotion, percentage: percentage)
        container.mainContext.insert(measurement)
        measurement.analysis = analysis
        analysis.emotionalState?.append(measurement)
    }
    
    try? container.mainContext.save()
    return container
}

#Preview {
    NavigationStack {
        AgentResponsesView()
            .modelContainer(createPreviewContainer())
    }
} 