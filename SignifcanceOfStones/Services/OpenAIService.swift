import Foundation

enum OpenAIError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed(String)
    case invalidModel
}

actor OpenAIService {
    private let apiKey: String
    private let model: String
    
    init(settings: AISettings) {
        self.apiKey = settings.apiKey
        // Ensure we're using a valid model
        self.model = AISettings.Model.availableModels.contains(settings.model) 
            ? settings.model 
            : AISettings.Model.defaultModel
    }
    
    func generateCompletion(prompt: String, temperature: Double) async throws -> String {
        // Validate model before making request
        guard AISettings.Model.availableModels.contains(model) else {
            print("❌ Invalid model: \(model)")
            throw OpenAIError.invalidModel
        }
        print("🔄 OpenAI Request - Temperature: \(temperature)")
        print("📝 Prompt length: \(prompt.count) characters")
        
        let requestBody = CompletionRequest(
            prompt: prompt,
            temperature: temperature,
            model: self.model
        )
        
        do {
            let data = try JSONEncoder().encode(requestBody)
            print("📦 Request payload size: \(data.count) bytes")
            
            guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
                print("❌ Invalid API URL")
                throw OpenAIError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = data
            
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw OpenAIError.invalidResponse
            }
            
            print("📡 Response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                let errorString = String(data: responseData, encoding: .utf8) ?? "Unknown error"
                print("❌ API Error: \(errorString)")
                throw OpenAIError.requestFailed(errorString)
            }
            
            let result = try JSONDecoder().decode(ChatCompletionResponse.self, from: responseData)
            let content = result.choices.first?.message.content ?? ""
            print("✅ Received response of length: \(content.count)")
            return content
            
        } catch {
            print("❌ OpenAI Service Error: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Request/Response Models
private struct CompletionRequest: Encodable {
    let model: String
    let messages: [Message]
    let temperature: Double
    
    init(prompt: String, temperature: Double, model: String) {
        self.model = model
        self.messages = [Message(role: "user", content: prompt)]
        self.temperature = temperature
    }
}

private struct Message: Codable {
    let role: String
    let content: String
}

private struct ChatCompletionResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
}

private struct ErrorResponse: Codable {
    let error: APIError
    
    struct APIError: Codable {
        let message: String
    }
} 