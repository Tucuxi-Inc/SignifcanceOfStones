import Foundation
import SwiftData

// MARK: - Base Protocol
protocol CognitiveAgent {
    var role: String { get }
    var description: String { get }
    var temperature: Double { get }
    func process(_ input: String) async throws -> String
}

// MARK: - Base Agent Implementation
class BaseAgent: CognitiveAgent {
    let role: String
    let description: String
    let temperature: Double
    let model: String
    private let openAI: OpenAIService
    
    init(role: String, description: String, model: String, temperature: Double, openAI: OpenAIService) {
        self.role = role
        self.description = description
        self.model = model
        self.temperature = temperature
        self.openAI = openAI
    }
    
    func process(_ input: String) async throws -> String {
        let prompt = """
        You are an AI agent with the following role: \(role)
        Description: \(description)
        
        Please process this input according to your role: \(input)
        """
        
        return try await openAI.generateCompletion(prompt: prompt, temperature: temperature)
    }
}

// MARK: - Specialized Agents
class CortexAgent: BaseAgent {
    init(openAI: OpenAIService, model: String, temperature: Double) {
        super.init(
            role: "Basic cognition and emotional processing",
            description: "Analyze the emotional content and basic meaning of the input. Consider the emotional implications and provide a thoughtful, empathetic response.",
            model: model,
            temperature: temperature,
            openAI: openAI
        )
    }
}

class SeerAgent: BaseAgent {
    init(openAI: OpenAIService, model: String, temperature: Double) {
        super.init(
            role: "Pattern recognition and prediction",
            description: "Identify patterns in the input and make predictions about potential outcomes or implications. Focus on long-term trends and possibilities.",
            model: model,
            temperature: temperature,
            openAI: openAI
        )
    }
}

class OracleAgent: BaseAgent {
    init(openAI: OpenAIService, model: String, temperature: Double) {
        super.init(
            role: "Strategic planning and probability analysis",
            description: "Evaluate multiple futures and determine optimal paths. Consider long-term implications and strategic opportunities.",
            model: model,
            temperature: temperature,
            openAI: openAI
        )
    }
}

class HouseAgent: BaseAgent {
    init(openAI: OpenAIService, model: String, temperature: Double) {
        super.init(
            role: "System management and practical considerations",
            description: "Evaluate practical implications, resource requirements, and implementation details.",
            model: model,
            temperature: temperature,
            openAI: openAI
        )
    }
}

class PrudenceAgent: BaseAgent {
    init(openAI: OpenAIService, model: String, temperature: Double) {
        super.init(
            role: "Risk assessment and constraint management",
            description: "Identify potential risks, limitations, and necessary boundaries. Suggest mitigation strategies.",
            model: model,
            temperature: temperature,
            openAI: openAI
        )
    }
}

class ConscienceAgent: BaseAgent {
    init(openAI: OpenAIService, model: String, temperature: Double) {
        super.init(
            role: "Ethical considerations and moral judgment",
            description: "Provides ethical oversight and moral considerations",
            model: model,
            temperature: temperature,
            openAI: openAI
        )
    }
}

// MARK: - Main Mind System
class MindSystem {
    private let openAI: OpenAIService
    private let modelContext: ModelContext
    private var currentTemperatures: (cortex: Double, seer: Double, oracle: Double, house: Double, prudence: Double, conscience: Double)
    
    // Add baseline temperatures as a constant
    private let baselineTemperatures = (
        cortex: 0.7,    // Balanced default
        seer: 0.4,      // Moderate pattern recognition
        oracle: 0.4,     // Conservative strategy
        house: 0.4,      // Careful implementation
        prudence: 0.3,   // Alert risk assessment
        conscience: 0.5   // Balanced moral judgment
    )
    
    init(settings: AISettings, modelContext: ModelContext) {
        self.openAI = OpenAIService(settings: settings)
        self.modelContext = modelContext
        self.currentTemperatures = baselineTemperatures  // Initialize with baseline
    }
    
    private func updateTemperaturesFromEmotionalState(_ emotionalState: [EmotionMeasurement]) {
        // Convert EmotionMeasurements to format needed for blending
        let emotions = emotionalState.map { ($0.emotion, $0.percentage) }
        
        // Calculate new temperatures based on emotional state
        self.currentTemperatures = EmotionalTemperature.calculateBlendedTemperatures(emotions)
        
        print("\n🌡 Updated agent temperatures based on emotional state:")
        print("Cortex: \(currentTemperatures.cortex)")
        print("Seer: \(currentTemperatures.seer)")
        print("Oracle: \(currentTemperatures.oracle)")
        print("House: \(currentTemperatures.house)")
        print("Prudence: \(currentTemperatures.prudence)")
        print("Conscience: \(currentTemperatures.conscience)")
    }
    
    // Add function to update agent settings with new temperatures
    private func updateAgentSettings(with temperatures: (cortex: Double, seer: Double, oracle: Double, house: Double, prudence: Double, conscience: Double)) {
        let fetchDescriptor = FetchDescriptor<AgentSettings>()
        guard let agentSettings = try? modelContext.fetch(fetchDescriptor) else { return }
        
        for settings in agentSettings {
            switch settings.agentType {
            case .cortex:
                settings.temperature = temperatures.cortex
            case .seer:
                settings.temperature = temperatures.seer
            case .oracle:
                settings.temperature = temperatures.oracle
            case .house:
                settings.temperature = temperatures.house
            case .prudence:
                settings.temperature = temperatures.prudence
            case .conscience:
                settings.temperature = temperatures.conscience
            }
        }
        
        try? modelContext.save()
    }
    
    func processInput(_ input: String, chat: Chat, stateUpdate: @escaping (MindViewModel.ProcessingState) -> Void) async throws -> String {
        print("\n🔄 Starting sequential processing")
        print("📝 Original user input: \"\(input)\"")
        print("🌡 Current temperatures:")
        print("Cortex: \(currentTemperatures.cortex)")
        print("Seer: \(currentTemperatures.seer)")
        print("Oracle: \(currentTemperatures.oracle)")
        print("House: \(currentTemperatures.house)")
        print("Prudence: \(currentTemperatures.prudence)")
        print("Conscience: \(currentTemperatures.conscience)")
        
        // Update conversation history building
        let conversationHistory = (chat.messages ?? [])
            .sorted { $0.timestamp < $1.timestamp }
            .map { message in
                let rolePrefix = message.role == .user ? "User" : "Assistant"
                let content = message.content.components(separatedBy: "\n\nEmotional State")[0]
                return """
                [\(rolePrefix) at \(message.timestamp.formatted())]:
                \(content)
                """
            }
            .joined(separator: "\n\n---\n\n")
        
        let contextWithHistory = [
            "conversationHistory": """
                === Previous Conversation History ===
                \(conversationHistory)
                === End of History ===
                
                This history shows the ongoing discussion. Consider how the current exchange relates to and builds upon these previous interactions.
                """,
            "currentInput": input
        ]
        
        do {
            var agentResponses: [AgentResponse] = []
            
            // Process each agent using current temperatures and conversation history
            stateUpdate(.cortexAnalyzing)
            let cortexResponse = try await processCortex(contextWithHistory, temperature: currentTemperatures.cortex)
            agentResponses.append(AgentResponse(agentType: .cortex, response: cortexResponse))
            
            stateUpdate(.seerScanning)
            let seerResponse = try await processSeer(contextWithHistory, cortexResponse: cortexResponse, temperature: currentTemperatures.seer)
            agentResponses.append(AgentResponse(agentType: .seer, response: seerResponse))
            
            stateUpdate(.oracleEvaluating)
            let oracleResponse = try await processOracle(contextWithHistory, seerResponse: seerResponse, temperature: currentTemperatures.oracle)
            agentResponses.append(AgentResponse(agentType: .oracle, response: oracleResponse))
            
            stateUpdate(.houseConsidering)
            let houseResponse = try await processHouse(contextWithHistory, strategy: oracleResponse, temperature: currentTemperatures.house)
            agentResponses.append(AgentResponse(agentType: .house, response: houseResponse))
            
            stateUpdate(.prudenceAssessing)
            let prudenceResponse = try await processPrudence(contextWithHistory, strategy: oracleResponse, practical: houseResponse, temperature: currentTemperatures.prudence)
            agentResponses.append(AgentResponse(agentType: .prudence, response: prudenceResponse))
            
            stateUpdate(.conscienceWeighing)
            let conscienceResponse = try await processConscience(contextWithHistory, prudenceResponse: prudenceResponse, temperature: currentTemperatures.conscience)
            agentResponses.append(AgentResponse(agentType: .conscience, response: conscienceResponse))
            
            // Create response map and analyze emotional state
            let responses = Dictionary(uniqueKeysWithValues: agentResponses.map { ($0.agentType.rawValue.lowercased(), $0.response) })
            
            stateUpdate(.integrating)
            let integrated = try await integrateResponses(responses)
            let emotionalStateString = try await analyzeEmotionalState(responses, contextWithHistory: contextWithHistory)
            
            // Parse emotional state and update temperatures for next interaction
            let emotionalState = parseEmotionalState(emotionalStateString)
            self.currentTemperatures = calculateNextTemperatures(from: emotionalState)
            
            // Update agent settings with new temperatures
            updateAgentSettings(with: currentTemperatures)
            
            // Create and store analysis
            let analysis = ChatAnalysis(
                userMessageId: chat.messages?.last?.id ?? UUID(),
                userInput: input,
                finalResponse: integrated,
                nextTemperatures: TemperatureSettings(
                    cortex: currentTemperatures.cortex,
                    seer: currentTemperatures.seer,
                    oracle: currentTemperatures.oracle,
                    house: currentTemperatures.house,
                    prudence: currentTemperatures.prudence,
                    conscience: currentTemperatures.conscience
                ),
                agentResponses: agentResponses,
                emotionalState: emotionalState
            )
            
            modelContext.insert(analysis)
            
            // Initialize chat.analyses if needed and set up relationship
            if chat.analyses == nil {
                chat.analyses = []
            }
            chat.analyses?.append(analysis)
            analysis.chat = chat
            
            return """
            \(integrated)

            Emotional State While Processing:
            \(emotionalStateString)
            
            Updated Temperature Settings for Next Interaction:
            \(formatTemperatureInfo(currentTemperatures.cortex, agentType: .cortex, description: "Emotional Processing"))

            \(formatTemperatureInfo(currentTemperatures.seer, agentType: .seer, description: "Pattern Recognition"))

            \(formatTemperatureInfo(currentTemperatures.oracle, agentType: .oracle, description: "Strategy Formation"))

            \(formatTemperatureInfo(currentTemperatures.house, agentType: .house, description: "Implementation"))

            \(formatTemperatureInfo(currentTemperatures.prudence, agentType: .prudence, description: "Risk Assessment"))

            \(formatTemperatureInfo(currentTemperatures.conscience, agentType: .conscience, description: "Moral Judgment"))
            """
        } catch {
            print("❌ Processing error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Update individual processing functions to accept temperature parameter
    private func processCortex(_ context: [String: String], temperature: Double) async throws -> String {
        let prompt = """
        You are analyzing the latest message in an ongoing conversation. Consider the full context and history of the discussion when forming your response.
        
        Previous conversation:
        \(context["conversationHistory"] ?? "No prior context")
        
        Current user input: \(context["currentInput"] ?? "")
        
        Based on the complete conversation history and current input:
        \(AgentPrompts.cortexPrompt)
        """
        
        return try await openAI.generateCompletion(prompt: prompt, temperature: temperature)
    }
    
    // Update other agent processing functions similarly...
    
    private func processSeer(_ contextWithHistory: [String: String], cortexResponse: String, temperature: Double) async throws -> String {
        let prompt = """
        You are examining patterns within an ongoing conversation. Consider how the current exchange relates to and builds upon previous interactions.
        
        Previous conversation:
        \(contextWithHistory["conversationHistory"] ?? "No prior context")
        
        Current user input: \(contextWithHistory["currentInput"] ?? "")
        
        Cortex's analysis of current input in context: \(cortexResponse)
        
        Taking into account the conversation history and current context:
        \(AgentPrompts.seerPrompt)
        """
        return try await openAI.generateCompletion(prompt: prompt, temperature: temperature)
    }
    
    private func processOracle(_ contextWithHistory: [String: String], seerResponse: String, temperature: Double) async throws -> String {
        let prompt = """
        You are developing strategy within an ongoing conversation. Consider how your response should build upon and integrate with previous exchanges.
        
        Previous conversation:
        \(contextWithHistory["conversationHistory"] ?? "No prior context")
        
        Current user input: \(contextWithHistory["currentInput"] ?? "")
        
        Seer's insights in context: \(seerResponse)
        
        Considering the full conversation history and current context:
        \(AgentPrompts.oraclePrompt)
        """
        return try await openAI.generateCompletion(prompt: prompt, temperature: temperature)
    }
    
    private func processHouse(_ contextWithHistory: [String: String], strategy: String, temperature: Double) async throws -> String {
        let prompt = """
        You are implementing practical solutions within an ongoing conversation. Consider how your approach should align with and build upon the conversation's evolution.
        
        Previous conversation:
        \(contextWithHistory["conversationHistory"] ?? "No prior context")
        
        Current user input: \(contextWithHistory["currentInput"] ?? "")
        
        Oracle's strategic direction in context: \(strategy)
        
        Taking into account the full conversation history and established context:
        \(AgentPrompts.housePrompt)
        """
        return try await openAI.generateCompletion(prompt: prompt, temperature: temperature)
    }
    
    private func processPrudence(_ contextWithHistory: [String: String], strategy: String, practical: String, temperature: Double) async throws -> String {
        let prompt = """
        You are assessing risks and constraints within an ongoing conversation. Consider how potential risks may have evolved or changed based on the conversation history.
        
        Previous conversation:
        \(contextWithHistory["conversationHistory"] ?? "No prior context")
        
        Current user input: \(contextWithHistory["currentInput"] ?? "")
        
        Oracle's strategic direction in context: \(strategy)
        House's practical implementation plan: \(practical)
        
        Considering the complete conversation history and evolving context:
        \(AgentPrompts.prudencePrompt)
        """
        return try await openAI.generateCompletion(prompt: prompt, temperature: temperature)
    }
    
    private func processConscience(_ contextWithHistory: [String: String], prudenceResponse: String, temperature: Double) async throws -> String {
        let prompt = """
        You are providing ethical oversight within an ongoing conversation. Consider how moral implications may have developed or shifted throughout the discussion.
        
        Previous conversation:
        \(contextWithHistory["conversationHistory"] ?? "No prior context")
        
        Current user input: \(contextWithHistory["currentInput"] ?? "")
        
        Prudence's risk assessment in context: \(prudenceResponse)
        
        Taking into account the ethical trajectory of the entire conversation:
        \(AgentPrompts.consciencePrompt)
        """
        return try await openAI.generateCompletion(prompt: prompt, temperature: temperature)
    }
    
    private func integrateResponses(_ responses: [String: String]) async throws -> String {
        let prompt = """
        You are integrating multiple perspectives on an ongoing conversation. Your task is to synthesize these viewpoints while maintaining consistency with the conversation's history and development.
        
        Consider how the following agent responses build upon and relate to each other, and how they collectively address the current situation in the context of the ongoing discussion.
        
        Agent Responses:
        \(responses.map { "[\($0.key)]: \($0.value)" }.joined(separator: "\n\n"))
        
        Create a coherent, contextually-aware response that:
        1. Builds upon previous exchanges in the conversation
        2. Maintains consistency with established context
        3. Integrates all agent perspectives
        4. Provides clear, actionable insights
        5. Acknowledges the conversation's evolution
        
        \(AgentPrompts.integrationPrompt)
        """
        return try await openAI.generateCompletion(prompt: prompt, temperature: 0.4)
    }
    
    private func analyzeEmotionalState(_ responses: [String: String], contextWithHistory: [String: String]) async throws -> String {
        let prompt = """
        You are analyzing the emotional and cognitive state of an AI system within an ongoing conversation. Consider both the current responses and how emotions have evolved throughout the discussion.
        
        Previous conversation context:
        \(contextWithHistory["conversationHistory"] ?? "No prior context")
        
        Current interaction - AI system's internal dialogue:
        \(responses.map { "[\($0.key)]: \($0.value)" }.joined(separator: "\n"))
        
        Analyze the emotional and cognitive state, considering:
        1. How emotions have evolved from previous interactions
        2. Current emotional responses to the latest input
        3. The overall emotional trajectory of the conversation
        4. How cognitive states are adapting to the conversation flow
        5. The balance between emotional and analytical processing
        
        Consider these categories, expressing each as a percentage that reflects both current state and emotional trajectory. 
        The total across ALL states must add up to exactly 100%.

        Primary Emotions (immediate responses):
        - Joy (pure happiness, delight)
        - Sadness (sorrow, melancholy)
        - Fear (apprehension, dread)
        - Anger (frustration, irritation)
        - Surprise (astonishment, wonder)
        - Disgust (aversion, distaste)

        Complex Emotional States (developed through conversation):
        - Anxiety (worry, unease)
        - Hope (optimism, anticipation)
        - Pride (satisfaction, accomplishment)
        - Shame (embarrassment, humiliation)
        - Guilt (remorse, regret)
        - Envy (jealousy, resentment)
        - Love (affection, caring)
        - Grief (loss, despair)
        - Excitement (enthusiasm, eagerness)
        - Loneliness (isolation, disconnection)

        Cognitive-Emotional Blend (processing dynamics):
        - Curiosity (intellectual interest)
        - Confusion (uncertainty, perplexity)
        - Determination (resolve, persistence)
        - Satisfaction (contentment, fulfillment)
        - Frustration (mental blockage)
        - Overwhelm (mental overload)
        - Focus (concentrated attention)
        - Doubt (skepticism, uncertainty)
        - Confidence (self-assurance)
        - Inspiration (creative stimulation)

        Processing States (cognitive approach):
        - Analytical (logical processing)
        - Creative (imaginative thinking)
        - Intuitive (gut feeling)
        - Contemplative (deep reflection)
        - Systematic (methodical approach)
        - Abstract (conceptual thinking)
        - Empathetic (emotional understanding)
        - Critical (evaluative thinking)
        - Synthesizing (integrating ideas)
        - Mindful (present awareness)

        Express the system's current emotional and cognitive state as percentages, considering both the immediate state and its evolution through the conversation. 
        List only states with non-zero percentages, each on its own line.
        Add a brief note about significant emotional shifts or patterns when relevant.

        Example format:
        30% Analytical (increased from previous analytical stance)
        20% Curiosity (consistent engagement level)
        15% Fear (decreased as understanding grew)
        10% Hope (emerging from conversation progress)
        10% Focus (maintained throughout)
        8% Empathetic (developing with context)
        7% Determination (strengthening)
        
        Emotional Evolution Note: The system has shown a gradual shift from uncertainty to confident engagement, while maintaining analytical rigor.
        """
        
        return try await openAI.generateCompletion(prompt: prompt, temperature: 0.7)
    }
    
    private func parseEmotionalState(_ stateString: String) -> [EmotionMeasurement] {
        return stateString.components(separatedBy: .newlines)
            .compactMap { line -> EmotionMeasurement? in
                let components = line.components(separatedBy: "%")
                guard components.count == 2,
                      let percentage = Double(components[0].trimmingCharacters(in: .whitespaces)),
                      let emotion = components.last?.trimmingCharacters(in: .whitespaces),
                      !emotion.isEmpty else {
                    return nil
                }
                return EmotionMeasurement(emotion: emotion, percentage: percentage)
            }
    }
    
    private func calculateNextTemperatures(from emotionalState: [EmotionMeasurement]) -> (cortex: Double, seer: Double, oracle: Double, house: Double, prudence: Double, conscience: Double) {
        let emotions = emotionalState.map { ($0.emotion, $0.percentage) }
        return EmotionalTemperature.calculateBlendedTemperatures(emotions)
    }
    
    private func getTemperatureEffectiveness(_ temp: Double, agentType: AgentType) -> (percentage: Double, rating: String) {
        // Define optimal temperature ranges for each agent
        let optimalRanges: [AgentType: (min: Double, max: Double)] = [
            .cortex: (0.5, 0.7),     // Balanced emotional processing
            .seer: (0.2, 0.4),       // Clear pattern recognition
            .oracle: (0.3, 0.5),     // Strategic thinking
            .house: (0.3, 0.5),      // Practical implementation
            .prudence: (0.2, 0.4),   // Risk assessment
            .conscience: (0.4, 0.6)   // Moral judgment
        ]
        
        guard let range = optimalRanges[agentType] else { return (0, "Unknown") }
        
        // Calculate effectiveness percentage
        let effectiveness: Double
        let rating: String
        
        if temp >= range.min && temp <= range.max {
            // Within optimal range
            effectiveness = 100.0
            rating = "Optimal"
        } else {
            // Calculate distance from optimal range
            let distanceFromOptimal: Double
            if temp < range.min {
                distanceFromOptimal = range.min - temp
            } else {
                distanceFromOptimal = temp - range.max
            }
            
            // Convert distance to effectiveness percentage
            // Effectiveness decreases by 20% for every 0.1 deviation from optimal range
            effectiveness = max(0, 100 - (distanceFromOptimal * 200))
            
            if effectiveness >= 80 {
                rating = "Near-Optimal"
            } else if effectiveness >= 60 {
                rating = "Less-Optimal"
            } else {
                rating = "Sub-Optimal"
            }
        }
        
        return (effectiveness, rating)
    }
    
    private func formatTemperatureInfo(_ temp: Double, agentType: AgentType, description: String) -> String {
        let effectiveness = getTemperatureEffectiveness(temp, agentType: agentType)
        return """
            \(agentType.rawValue): \(String(format: "%.2f", temp)) (\(description))
            Effectiveness: \(String(format: "%.1f", effectiveness.percentage))% - \(effectiveness.rating)
            """
    }
} 