import Foundation
import SwiftData
import SwiftUI

@Model
final class AgentResponse {
    var id: UUID = UUID()
    var agentType: AgentType = AgentType.cortex
    var response: String = ""
    var timestamp: Date = Date()
    var analysis: ChatAnalysis?
    
    init(
        id: UUID = UUID(),
        agentType: AgentType,
        response: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.agentType = agentType
        self.response = response
        self.timestamp = timestamp
    }
} 