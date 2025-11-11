import Foundation

class APIClient {
    static let shared = APIClient()

    func fetchModels(for provider: Provider, token: String? = nil) async throws -> [LLMModel] {
        switch provider {
        case .openrouter:
            let url = URL(string: "https://openrouter.ai/api/v1/models")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenRouterModelsResponse.self, from: data)
            return response.data
        case .openai:
            let url = URL(string: "https://api.openai.com/v1/models")!
            var request = URLRequest(url: url)
            if let token = token, !token.isEmpty {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(OpenAIModelsResponse.self, from: data)
            return response.data.map { LLMModel(id: $0.id, name: $0.id, description: nil) } // Simplify
        case .anthropic:
            let url = URL(string: "https://api.anthropic.com/v1/models")!
            var request = URLRequest(url: url)
            if let token = token, !token.isEmpty {
                request.setValue(token, forHTTPHeaderField: "x-api-key")
                request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            }
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(AnthropicModelsResponse.self, from: data)
            return response.data.map { LLMModel(id: $0.id, name: $0.display_name, description: nil) }
        }
    }

    func sendChatRequest(provider: Provider, model: String, prompt: String, apiKey: String) async throws -> String {
        let url: URL
        var request: URLRequest
        var body: [String: Any]

        switch provider {
        case .openrouter:
            url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
            request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            body = [
                "model": model,
                "messages": [
                    ["role": "user", "content": prompt]
                ]
            ]
        case .openai:
            url = URL(string: "https://api.openai.com/v1/chat/completions")!
            request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            body = [
                "model": model,
                "messages": [
                    ["role": "user", "content": prompt]
                ]
            ]
        case .anthropic:
            url = URL(string: "https://api.anthropic.com/v1/messages")!
            request = URLRequest(url: url)
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            body = [
                "model": model,
                "max_tokens": 4096,
                "messages": [
                    ["role": "user", "content": prompt]
                ]
            ]
        }

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // Log error response
            if let errorData = String(data: data, encoding: .utf8) {
                print("API Error Response: \(errorData)")
            }
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        switch provider {
        case .openrouter, .openai:
            if let choices = json?["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content
            } else {
                throw URLError(.cannotParseResponse)
            }
        case .anthropic:
            if let content = json?["content"] as? [[String: Any]],
               let firstContent = content.first,
               let text = firstContent["text"] as? String {
                return text
            } else {
                throw URLError(.cannotParseResponse)
            }
        }
    }

    func checkForUpdates() async throws -> GitHubRelease? {
        let url = URL(string: "https://api.github.com/repos/nemot/inplace_ai/releases/latest")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        return release
    }
}
