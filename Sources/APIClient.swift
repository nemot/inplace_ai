import Foundation

class APIClient {
    static let shared = APIClient()

    private let baseURL = "https://openrouter.ai/api/v1"

    func fetchModels() async throws -> [LLMModel] {
        let url = URL(string: "\(baseURL)/models")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenRouterModelsResponse.self, from: data)
        return response.data
    }

    func sendChatRequest(model: String, prompt: String, apiKey: String) async throws -> String {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let choices = json?["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        } else {
            throw URLError(.cannotParseResponse)
        }
    }

    func checkForUpdates() async throws -> GitHubRelease? {
        let url = URL(string: "https://api.github.com/repos/nemot/inplace_ai/releases/latest")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        return release
    }
}
