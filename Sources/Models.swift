import Foundation

struct Workflow: Codable, Identifiable {
    var id = UUID()
    var name: String = ""
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
