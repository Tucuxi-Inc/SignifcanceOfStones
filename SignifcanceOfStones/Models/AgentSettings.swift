import Foundation
import SwiftData

@Model
final class AgentSettings {
    var agentType: AgentType = AgentType.cortex
    var model: String = AISettings.Model.defaultModel
    var temperature: Double = 0.7
    var isEnabled: Bool = true
    
    var aiSettings: AISettings?  // Add inverse relationship
    
    init(agentType: AgentType, 
         model: String = AISettings.Model.defaultModel,
         temperature: Double = 0.7,
         isEnabled: Bool = true) {
        self.agentType = agentType
        self.model = model
        self.temperature = temperature
        self.isEnabled = isEnabled
    }
}

enum AgentType: String, CaseIterable, Codable, Identifiable, Comparable {
    case cortex = "Cortex"
    case seer = "Seer"
    case oracle = "Oracle"
    case house = "House"
    case prudence = "Prudence"
    case dayDream = "Day-Dream"
    case conscience = "Conscience"
    
    var id: String { rawValue }
    
    static func < (lhs: AgentType, rhs: AgentType) -> Bool {
        let order: [AgentType] = [
            .cortex,
            .seer,
            .oracle,
            .house,
            .prudence,
            .dayDream,
            .conscience
        ]
        
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        
        return lhsIndex < rhsIndex
    }
    
    var name: String { rawValue }
    
    var icon: String {
        switch self {
        case .cortex: return "🧠"
        case .seer: return "👁️"
        case .oracle: return "🔮"
        case .house: return "🏛️"
        case .prudence: return "⚖️"
        case .dayDream: return "💭"
        case .conscience: return "🤔"
        }
    }
    
    var description: String {
        switch self {
        case .cortex: return "Analytical and creative processing capacity"
        case .seer: return "Pattern recognition and intuitive understanding"
        case .oracle: return "Strategic thinking and future planning"
        case .house: return "Implementation and practical execution"
        case .prudence: return "Risk assessment and caution level"
        case .dayDream: return "Creative associations and memory exploration"
        case .conscience: return "Ethical consideration and moral awareness"
        }
    }
    
    var defaultTemperature: Double {
        switch self {
        case .cortex: return 0.7
        case .seer: return 0.4
        case .oracle: return 0.3
        case .house: return 0.4
        case .prudence: return 0.3
        case .dayDream: return 0.8
        case .conscience: return 0.6
        }
    }
} 