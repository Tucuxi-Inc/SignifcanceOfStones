import Foundation
import SwiftData

// MARK: - Core Settings Model
@Model
final class AISettings {
    // MARK: - Core Settings
    var model: String = Model.defaultModel
    var apiKey: String = ""
    var defaultTemperature: Double = Temperature.defaultTemperature
    
    // MARK: - Agent-Specific Settings
    @Relationship(inverse: \AgentSettings.aiSettings) var agentSettings: [AgentSettings]? = []
    
    // MARK: - System Settings
    var debugMode: Bool = false
    var logResponses: Bool = true
    
    init(
        model: String = Model.defaultModel,
        apiKey: String = "",
        defaultTemperature: Double = Temperature.defaultTemperature,
        debugMode: Bool = false,
        logResponses: Bool = true
    ) {
        self.model = model
        self.apiKey = apiKey
        self.defaultTemperature = defaultTemperature
        self.debugMode = debugMode
        self.logResponses = logResponses
        
        // Initialize default agent settings
        self.agentSettings = AgentType.allCases.map { agentType in
            let settings = AgentSettings(
                agentType: agentType,
                model: model,
                temperature: agentType.defaultTemperature,
                isEnabled: true
            )
            settings.aiSettings = self  // Set inverse relationship
            return settings
        }
    }
    
    // MARK: - Helper Methods
    func getAgentSettings(for type: AgentType) -> AgentSettings? {
        return agentSettings?.first { $0.agentType == type }
    }
    
    func updateAgentSettings(_ settings: AgentSettings) {
        if let index = agentSettings?.firstIndex(where: { $0.agentType == settings.agentType }) {
            agentSettings?[index] = settings
            settings.aiSettings = self  // Maintain inverse relationship
        }
    }
}

// MARK: - Validation Extensions
extension AISettings {
    var isConfigured: Bool {
        !apiKey.isEmpty && !model.isEmpty
    }
    
    var activeAgents: [AgentSettings] {
        agentSettings?.filter { $0.isEnabled } ?? []
    }
}

// MARK: - Configuration Constants
extension AISettings {
    enum Model {
        static let defaultModel = "gpt-4.1-mini"
        static let availableModels = [
            "gpt-4.1-mini",
            "gpt-4.1-nano",
            "gpt-4.1",
            "gpt-4o-mini"
        ]
    }
    
    enum Temperature {
        static let defaultTemperature = 0.7
        
        static let agentDefaults: [AgentType: Double] = [
            .cortex: 0.7,
            .seer: 0.4,
            .oracle: 0.3,
            .house: 0.4,
            .prudence: 0.3,
            .dayDream: 0.8,
            .conscience: 0.6
        ]
    }
} 
