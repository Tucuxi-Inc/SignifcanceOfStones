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
        
        // Build a limited conversation history - including only the last 3 exchanges
        // TODO: Future enhancement - implement similarity search across all chat history to find relevant past exchanges
        // This would involve:
        // 1. Creating embeddings for user questions and system responses
        // 2. Using vector similarity to find related past conversations
        // 3. Including only the most relevant past exchanges as additional context
        let recentMessages = (chat.messages ?? [])
            .sorted { $0.timestamp < $1.timestamp }
            .suffix(6) // Last 3 exchanges (3 user inputs + 3 system responses)
        
        let conversationHistory = recentMessages
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
                === Recent Conversation History (Last 3 Exchanges) ===
                \(conversationHistory)
                === End of History ===
                
                This history shows recent interactions. Consider how the current exchange relates to these recent interactions.
                """,
            "userInput": input
        ]
        
        do {
            var agentResponses: [AgentResponse] = []
            
            // Process each agent using current temperatures and conversation history
            stateUpdate(.cortexAnalyzing)
            let cortexResponse = try await processCortex(contextWithHistory, temperature: currentTemperatures.cortex)
            agentResponses.append(AgentResponse(agentType: .cortex, response: cortexResponse))
            
            stateUpdate(.seerScanning)
            // Pass both the user input and conversation history to Seer
            // But include special instructions to focus primarily on current input
            let seerResponse = try await processSeer(contextWithHistory, cortexResponse: cortexResponse, temperature: currentTemperatures.seer)
            agentResponses.append(AgentResponse(agentType: .seer, response: seerResponse))
            
            stateUpdate(.oracleEvaluating)
            let oracleResponse = try await processOracle(contextWithHistory, seerResponse: seerResponse, temperature: currentTemperatures.oracle)
            agentResponses.append(AgentResponse(agentType: .oracle, response: oracleResponse))
            
            stateUpdate(.houseConsidering)
            let houseResponse = try await processHouse(contextWithHistory, oracleResponse: oracleResponse, temperature: currentTemperatures.house)
            agentResponses.append(AgentResponse(agentType: .house, response: houseResponse))
            
            stateUpdate(.prudenceAssessing)
            let prudenceResponse = try await processPrudence(oracleResponse, houseResponse: houseResponse, temperature: currentTemperatures.prudence)
            agentResponses.append(AgentResponse(agentType: .prudence, response: prudenceResponse))
            
            stateUpdate(.conscienceWeighing)
            let conscienceResponse = try await processConscience(contextWithHistory, prudenceResponse: prudenceResponse, temperature: currentTemperatures.conscience)
            agentResponses.append(AgentResponse(agentType: .conscience, response: conscienceResponse))
            
            // Create response map for integration
            let responses = [
                "userInput": input,
                "cortexResponse": cortexResponse,
                "seerResponse": seerResponse,
                "oracleResponse": oracleResponse,
                "houseResponse": houseResponse,
                "prudenceResponse": prudenceResponse,
                "conscienceResponse": conscienceResponse
            ]
            
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
    
    // Updated processing functions with improved focus
    private func processCortex(_ context: [String: String], temperature: Double) async throws -> String {
        let prompt = """
        You are analyzing the latest message in an ongoing conversation. Consider the context when forming your response.
        
        Previous conversation:
        \(context["conversationHistory"] ?? "No prior context")
        
        Current user input: \(context["userInput"] ?? "")
        
        Based on the current input:
        \(AgentPrompts.cortexPrompt.replacingOccurrences(of: "{userInput}", with: context["userInput"] ?? ""))
        """
        
        return try await openAI.generateCompletion(prompt: prompt, temperature: temperature)
    }
    
    // Modified Seer processing to handle history but focus on current input
    private func processSeer(_ contextWithHistory: [String: String], cortexResponse: String, temperature: Double) async throws -> String {
        let context = [
            "userInput": contextWithHistory["userInput"] ?? "",
            "cortexResponse": cortexResponse
        ]
        
        let prompt = """
        You are the Seer agent, focused on pattern recognition and prediction.
        
        Previous conversation:
        \(contextWithHistory["conversationHistory"] ?? "No prior context")
        
        IMPORTANT: While you can see the conversation history, focus primarily on the current user input when detecting patterns. If there are relevant patterns across multiple interactions, you may note them, but avoid suggesting the user is repeating themselves unless they clearly are doing so in their current message.
        
        Current user input: \(contextWithHistory["userInput"] ?? "")
        Cortex's analysis: \(cortexResponse)
        
        \(AgentPrompts.replacePlaceholders(AgentPrompts.seerPrompt, context: context))
        """
        return try await openAI.generateCompletion(prompt: prompt, temperature: temperature)
    }
    
    private func processOracle(_ contextWithHistory: [String: String], seerResponse: String, temperature: Double) async throws -> String {
        let context = [
            "userInput": contextWithHistory["userInput"] ?? "",
            "seerResponse": seerResponse
        ]
        
        let prompt = """
        You are developing strategy within an ongoing conversation.
        
        Previous conversation:
        \(contextWithHistory["conversationHistory"] ?? "No prior context")
        
        Current user input: \(contextWithHistory["userInput"] ?? "")
        
        Seer's insights: \(seerResponse)
        
        Based on this information:
        \(AgentPrompts.replacePlaceholders(AgentPrompts.oraclePrompt, context: context))
        """
        return try await openAI.generateCompletion(prompt: prompt, temperature: temperature)
    }
    
    // Modified House processing function to focus on the 4 points but include conversation context
    private func processHouse(_ contextWithHistory: [String: String], oracleResponse: String, temperature: Double) async throws -> String {
        let context = [
            "userInput": contextWithHistory["userInput"] ?? "",
            "oracleResponse": oracleResponse
        ]
        
        let prompt = """
        You are the House agent, responsible for practical implementation and system resources.
        
        Previous conversation:
        \(contextWithHistory["conversationHistory"] ?? "No prior context")
        
        Current user input: \(contextWithHistory["userInput"] ?? "")
        
        \(AgentPrompts.replacePlaceholders(AgentPrompts.housePrompt, context: context))
        
        IMPORTANT: Structure your response with these four distinct sections:
        
        # 1. FEASIBILITY
        [Your evaluation of real-world feasibility]
        
        # 2. RESOURCES
        [Your analysis of resource constraints]
        
        # 3. BOUNDARIES
        [Your assessment of system boundaries]
        
        # 4. GROUNDING
        [Your approach to grounding ideas in reality]
        """
        return try await openAI.generateCompletion(prompt: prompt, temperature: temperature)
    }
    
    private func processPrudence(_ oracleResponse: String, houseResponse: String, temperature: Double) async throws -> String {
        let context = [
            "oracleResponse": oracleResponse,
            "houseResponse": houseResponse
        ]
        
        // Simplified prompt without conversation history to focus on risk assessment
        let prompt = """
        You are the Prudence agent, focused on risk assessment and boundary management.
        
        \(AgentPrompts.replacePlaceholders(AgentPrompts.prudencePrompt, context: context))
        
        Provide a detailed risk assessment, identifying specific concerns and potential mitigation strategies.
        """
        return try await openAI.generateCompletion(prompt: prompt, temperature: temperature)
    }
    
    private func processConscience(_ contextWithHistory: [String: String], prudenceResponse: String, temperature: Double) async throws -> String {
        let context = [
            "userInput": contextWithHistory["userInput"] ?? "",
            "prudenceResponse": prudenceResponse
        ]
        
        let prompt = """
        You are the Conscience agent, providing ethical oversight and moral judgment.
        
        Previous conversation:
        \(contextWithHistory["conversationHistory"] ?? "No prior context")
        
        Current user input: \(contextWithHistory["userInput"] ?? "")
        
        \(AgentPrompts.replacePlaceholders(AgentPrompts.consciencePrompt, context: context))
        
        Focus on the ethical implications of the proposed approach, considering all stakeholders that might be impacted.
        """
        return try await openAI.generateCompletion(prompt: prompt, temperature: temperature)
    }
    
    private func integrateResponses(_ responses: [String: String]) async throws -> String {
        let prompt = """
        You are integrating multiple perspectives into a coherent response to the user's question.
        
        \(AgentPrompts.replacePlaceholders(AgentPrompts.integrationPrompt, context: responses))
        
        Create a balanced response that directly addresses the user's question while incorporating the key insights from each agent.
        """
        return try await openAI.generateCompletion(prompt: prompt, temperature: 0.4)
    }
    
    private func analyzeEmotionalState(_ responses: [String: String], contextWithHistory: [String: String]) async throws -> String {
        let prompt = """
        You are analyzing the emotional and cognitive state of an AI system.
        
        Current interaction - AI system's internal dialogue:
        Cortex (Emotional Processing): \(responses["cortexResponse"] ?? "")
        Seer (Pattern Recognition): \(responses["seerResponse"] ?? "")
        Oracle (Strategic Analysis): \(responses["oracleResponse"] ?? "")
        House (Practical Implementation): \(responses["houseResponse"] ?? "")
        Prudence (Risk Assessment): \(responses["prudenceResponse"] ?? "")
        Conscience (Ethical Evaluation): \(responses["conscienceResponse"] ?? "")
        
        Analyze the emotional and cognitive state, considering:
        1. Current emotional responses to the latest input
        2. The balance between emotional and analytical processing
        
        Consider these categories, expressing each as a percentage that reflects the current state. 
        The total across ALL states must add up to exactly 100%.

        Primary Emotions (immediate responses):
        - Joy (pure happiness, delight)
        - Sadness (sorrow, melancholy)
        - Fear (apprehension, dread)
        - Anger (frustration, irritation)
        - Surprise (astonishment, wonder)
        - Disgust (aversion, distaste)

        Complex Emotional States (developed responses):
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

        Express the system's current emotional and cognitive state as percentages. 
        List only states with non-zero percentages, each on its own line.
        Add a brief note about significant patterns when relevant.

        Example format:
        30% Analytical
        20% Curiosity
        15% Fear
        10% Hope
        10% Focus
        8% Empathetic
        7% Determination
        
        Emotional Note: [Brief observation about the overall emotional state]
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
