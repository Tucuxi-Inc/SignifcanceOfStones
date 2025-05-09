import Foundation
import SwiftData

@Model
final class Chat {
    var id: UUID = UUID()
    var title: String = "New Chat"
    var timestamp: Date = Date()
    @Relationship(inverse: \ChatMessage.chat) var messages: [ChatMessage]? = []
    @Relationship(inverse: \ChatAnalysis.chat) var analyses: [ChatAnalysis]? = []
    
    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        timestamp: Date = Date(),
        messages: [ChatMessage] = [],
        analyses: [ChatAnalysis] = []
    ) {
        self.id = id
        self.title = title
        self.timestamp = timestamp
        self.messages = messages
        self.analyses = analyses
        
        // Set up inverse relationships
        messages.forEach { $0.chat = self }
        analyses.forEach { $0.chat = self }
    }
}

// Move TemperatureSettings out of ChatAnalysis to make it globally accessible
struct TemperatureSettings: Codable {
    var cortex: Double
    var seer: Double
    var oracle: Double
    var house: Double
    var prudence: Double
    var dayDream: Double
    var conscience: Double
    
    init(
        cortex: Double = 0.0,
        seer: Double = 0.0,
        oracle: Double = 0.0,
        house: Double = 0.0,
        prudence: Double = 0.0,
        dayDream: Double = 0.0,
        conscience: Double = 0.0
    ) {
        self.cortex = cortex
        self.seer = seer
        self.oracle = oracle
        self.house = house
        self.prudence = prudence
        self.dayDream = dayDream
        self.conscience = conscience
    }
    
    // Helper method to get a temperature for a specific agent type
    func get(for agentType: AgentType) -> Double {
        switch agentType {
        case .cortex: return cortex
        case .seer: return seer
        case .oracle: return oracle
        case .house: return house
        case .prudence: return prudence
        case .dayDream: return dayDream
        case .conscience: return conscience
        }
    }
    
    // Helper method to set a temperature for a specific agent type
    mutating func set(temperature: Double, for agentType: AgentType) {
        switch agentType {
        case .cortex: cortex = temperature
        case .seer: seer = temperature
        case .oracle: oracle = temperature
        case .house: house = temperature
        case .prudence: prudence = temperature
        case .dayDream: dayDream = temperature
        case .conscience: conscience = temperature
        }
    }
}

@Model
final class ChatAnalysis {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var userMessageId: UUID = UUID()
    var userInput: String = ""
    var finalResponse: String = ""
    var nextTemperatures: TemperatureSettings = TemperatureSettings()
    var chat: Chat?
    @Relationship(inverse: \AgentResponse.analysis) var agentResponses: [AgentResponse]? = []
    @Relationship(inverse: \EmotionMeasurement.analysis) var emotionalState: [EmotionMeasurement]? = []
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        userMessageId: UUID,
        userInput: String,
        finalResponse: String,
        nextTemperatures: TemperatureSettings = TemperatureSettings(),
        agentResponses: [AgentResponse] = [],
        emotionalState: [EmotionMeasurement] = []
    ) {
        self.id = id
        self.timestamp = timestamp
        self.userMessageId = userMessageId
        self.userInput = userInput
        self.finalResponse = finalResponse
        self.nextTemperatures = nextTemperatures
        self.agentResponses = agentResponses
        self.emotionalState = emotionalState
        
        // Set up inverse relationships
        agentResponses.forEach { $0.analysis = self }
        emotionalState.forEach { $0.analysis = self }
    }
}

@Model
final class EmotionMeasurement {
    var emotion: String = ""
    var percentage: Double = 0.0
    var analysis: ChatAnalysis?
    
    init(emotion: String, percentage: Double) {
        self.emotion = emotion
        self.percentage = percentage
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
} 