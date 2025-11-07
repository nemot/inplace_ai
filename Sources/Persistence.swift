import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()

    private let fileManager = FileManager.default
    private let workflowsFileName = "workflows.json"

    private var applicationSupportDirectory: URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("InplaceAI")
    }

    private var workflowsURL: URL? {
        applicationSupportDirectory?.appendingPathComponent(workflowsFileName)
    }

    private init() {
        createApplicationSupportDirectoryIfNeeded()
    }

    private func createApplicationSupportDirectoryIfNeeded() {
        guard let url = applicationSupportDirectory else { return }
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    func loadWorkflows() -> [Workflow] {
        guard let url = workflowsURL else { return [Workflow()] } // Default workflow
        do {
            let data = try Data(contentsOf: url)
            let workflows = try JSONDecoder().decode([Workflow].self, from: data)
            return workflows.isEmpty ? [Workflow()] : workflows
        } catch {
            print("Error loading workflows: \(error)")
            return [Workflow()]
        }
    }

    func saveWorkflows(_ workflows: [Workflow]) {
        guard let url = workflowsURL else { return }
        do {
            let data = try JSONEncoder().encode(workflows)
            try data.write(to: url)
        } catch {
            print("Error saving workflows: \(error)")
        }
    }

    func getAPIKey() -> String? {
        UserDefaults.standard.string(forKey: "openRouterAPIKey")
    }

    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "openRouterAPIKey")
    }


}
