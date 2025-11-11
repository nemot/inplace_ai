import Foundation

enum Provider: String, Codable, CaseIterable {
    case openrouter = "OpenRouter"
    case openai = "OpenAI"
    case anthropic = "Anthropic"
}

struct Workflow: Codable, Identifiable {
    var id = UUID()
    var name: String = ""
    var provider: Provider = .openrouter
    var token: String = ""
    var model: String = ""
    var prompt: String = ""
    var primaryHotkey: String = ""
    var optionalHotkey1: String = ""
    var optionalHotkey2: String = ""
    var outputMethod: OutputMethod = .pasteInPlace
}

enum OutputMethod: String, Codable, CaseIterable {
    case pasteInPlace = "Paste in Place"
    case banner = "Banner"
}

struct LLMModel: Codable {
    let id: String
    let name: String
    let description: String?
}

struct OpenRouterModelsResponse: Codable {
    let data: [LLMModel]
}

struct OpenAIModel: Codable {
    let id: String
    let object: String
}

struct OpenAIModelsResponse: Codable {
    let data: [OpenAIModel]
}

struct AnthropicModel: Codable {
    let id: String
    let display_name: String
    let type: String
}

struct AnthropicModelsResponse: Codable {
    let data: [AnthropicModel]
}

struct GitHubRelease: Codable {
    let tag_name: String
    let name: String
    let body: String?
    let published_at: String
    let html_url: String
}
