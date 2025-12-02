import Cocoa
import SwiftUI
import Combine
import ApplicationServices

let currentVersion = "0.0.1"

class StatusItemView: NSView {
    private let progressIndicator: NSProgressIndicator

    override init(frame frameRect: NSRect) {
        progressIndicator = NSProgressIndicator()
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        progressIndicator = NSProgressIndicator()
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        progressIndicator.style = .spinning
        progressIndicator.controlSize = .small
        progressIndicator.sizeToFit()
        progressIndicator.frame = bounds
        progressIndicator.autoresizingMask = [.width, .height]
        addSubview(progressIndicator)
        progressIndicator.startAnimation(nil)
    }
}

class StatusBarController: NSObject, NSApplicationDelegate, ObservableObject {
    var statusBar: NSStatusBar!
    var statusItem: NSStatusItem!
    var settingsWindow: NSWindow?
    @Published var workflows: [Workflow] = []
    private var statusItemView: StatusItemView?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the app from dock
        NSApp.setActivationPolicy(.accessory)

        // Check Accessibility
        if !AXIsProcessTrusted() {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "This app requires Accessibility permissions to simulate keyboard shortcuts and monitor global hotkeys. Please enable it in System Preferences > Security & Privacy > Privacy > Accessibility."
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Continue")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }

        // Load workflows
        workflows = PersistenceManager.shared.loadWorkflows()

        // Create status bar item
        statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: "brain", accessibilityDescription: "Inplace AI")
            } else {
                button.image = NSImage(named: NSImage.Name("NSApplicationIcon"))
            }
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }

        // Create menu
        let menu = NSMenu()
        menu.addItem(withTitle: "Settings", action: #selector(openSettings), keyEquivalent: "")
        menu.addItem(withTitle: "Check for Updates", action: #selector(checkForUpdates), keyEquivalent: "")
        menu.addItem(withTitle: "View Log", action: #selector(viewLog), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit Inplace AI", action: #selector(quitApp), keyEquivalent: "q")
        statusItem.menu = menu

        // Register hotkeys
        registerHotkeys()
    }

    func setProcessing(_ processing: Bool) {
        DispatchQueue.main.async {
            if processing {
                if self.statusItemView == nil {
                    self.statusItemView = StatusItemView(frame: NSRect(x: 0, y: 0, width: 22, height: 22))
                }
                self.statusItem.view = self.statusItemView
            } else {
                self.statusItem.view = nil
                if let button = self.statusItem.button {
                    if #available(macOS 11.0, *) {
                        button.image = NSImage(systemSymbolName: "brain", accessibilityDescription: "Inplace AI")
                    } else {
                        button.image = NSImage(named: NSImage.Name("NSApplicationIcon"))
                    }
                }
            }
        }
    }

    func registerHotkeys() {
        HotkeyManager.shared.registerHotkeys(for: workflows) { [weak self] workflow in
            guard let self = self else { return }
            Task {
                await ProcessingManager.shared.processWorkflow(workflow, statusController: self)
            }
        }
    }

    @objc func statusBarButtonClicked() {
        // Menu will be shown automatically
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView(controller: self)
            let hostingController = NSHostingController(rootView: settingsView)
            settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow?.styleMask = [.titled, .closable, .resizable]
            settingsWindow?.title = "Settings"
            settingsWindow?.isReleasedWhenClosed = false
            settingsWindow?.center()
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func checkForUpdates() {
        Task {
            do {
                if let latestRelease = try await APIClient.shared.checkForUpdates() {
                    let latestVersion = latestRelease.tag_name.replacingOccurrences(of: "v", with: "")
                    if latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                        // New version available
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            alert.messageText = "Update Available"
                            alert.informativeText = "A new version \(latestRelease.tag_name) is available. Current version: \(currentVersion)\n\n\(latestRelease.body ?? "")"
                            alert.addButton(withTitle: "Download")
                            alert.addButton(withTitle: "Later")
                            let response = alert.runModal()
                            if response == .alertFirstButtonReturn {
                                NSWorkspace.shared.open(URL(string: latestRelease.html_url)!)
                            }
                        }
                    } else {
                        // Up to date
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            alert.messageText = "Up to Date"
                            alert.informativeText = "You are running the latest version (\(currentVersion))."
                            alert.runModal()
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Update Check Failed"
                    alert.informativeText = "Could not check for updates: \(error.localizedDescription)"
                    alert.runModal()
                }
            }
        }
    }

    @objc func viewLog() {
        // Open terminal with tail -f on log file
        if let logPath = FileLogger.shared.getLogFilePath() {
            let script = """
            tell application "Terminal"
                activate
                do script "tail -f '\(logPath)'"
            end tell
            """
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]
            try? process.run()
        } else {
            // Fallback to Console.app if log file not available
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Console.app"))
        }
    }

    @objc func quitApp() {
        HotkeyManager.shared.unregisterAll()
        NSApp.terminate(nil)
    }
}



// Settings View
struct SettingsView: View {
    @ObservedObject var controller: StatusBarController

    @State private var workflows: [Workflow] = []
    @State private var models: [Provider: [LLMModel]] = [:]
    @State private var isLoadingModels = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Workflows")
                    .font(.headline)
                Spacer()
                Button("Add Workflow") {
                    addWorkflow()
                }
                .buttonStyle(.bordered)
            }

            ScrollView {
                VStack(spacing: 20) {
                    ForEach($workflows) { $workflow in
                        WorkflowView(workflow: $workflow, models: models, onRemove: {
                            if workflows.count > 1 {
                                workflows.removeAll { $0.id == workflow.id }
                            }
                        }, onProviderChange: { provider in
                            loadModelsIfNeeded(for: provider)
                        }, onTokenChange: { provider, token in
                            // Reload models if provider requires token
                            if provider == .openai || provider == .anthropic {
                                models[provider] = nil
                                loadModelsIfNeeded(for: provider, token: token)
                            }
                        })
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }

            HStack {
                Spacer()
                Button("Save") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .frame(width: 600, height: 800)
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            workflows = controller.workflows
            for provider in Provider.allCases {
                loadModelsIfNeeded(for: provider)
            }
        }
    }

    private func loadModelsIfNeeded(for provider: Provider, token: String? = nil) {
        if models[provider] == nil {
            Task {
                do {
                    let tokenToUse = token ?? PersistenceManager.shared.getProviderToken(provider)
                    let fetchedModels = try await APIClient.shared.fetchModels(for: provider, token: tokenToUse)
                    models[provider] = fetchedModels
                } catch {
                    print("Error loading models for \(provider): \(error)")
                    // Set empty models if failed
                    models[provider] = []
                }
            }
        }
    }

    private func addWorkflow() {
        workflows.append(Workflow())
    }

    private func saveSettings() {
        // Save last used configs
        for workflow in workflows {
            PersistenceManager.shared.setProviderToken(workflow.provider, token: workflow.token)
            PersistenceManager.shared.setProviderModel(workflow.provider, model: workflow.model)
        }
        controller.workflows = workflows
        PersistenceManager.shared.saveWorkflows(controller.workflows)
        controller.registerHotkeys()
    }
}

struct WorkflowView: View {
    @Binding var workflow: Workflow
    let models: [Provider: [LLMModel]]
    var onRemove: () -> Void
    var onProviderChange: (Provider) -> Void
    var onTokenChange: (Provider, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("Workflow Name", text: $workflow.name)
                    .textFieldStyle(.roundedBorder)
                Spacer()
                Button("Remove") {
                    onRemove()
                }
                .buttonStyle(.borderless)
            }

            Picker("Provider", selection: $workflow.provider) {
                ForEach(Provider.allCases, id: \.self) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: workflow.provider) { newProvider in
                onProviderChange(newProvider)
                // Pre-fill token and model from persistence
                if let savedToken = PersistenceManager.shared.getProviderToken(newProvider) {
                    workflow.token = savedToken
                }
                if let savedModel = PersistenceManager.shared.getProviderModel(newProvider) {
                    workflow.model = savedModel
                }
            }

            TextField("Token", text: $workflow.token)
                .textFieldStyle(.roundedBorder)
                .onChange(of: workflow.token) { newToken in
                    onTokenChange(workflow.provider, newToken)
                }

            Picker("Model", selection: $workflow.model) {
                ForEach(models[workflow.provider] ?? [], id: \.id) { model in
                    Text("\(model.id) - \(model.name ?? "")").tag(model.id)
                }
            }
            .pickerStyle(.menu)

            Text("Prompt")
            TextEditor(text: $workflow.prompt)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .font(.system(size: 14))
                .frame(height: 80)
                .background(Color.white.opacity(0.5))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            HStack {
                VStack {
                    Text("Primary Hotkey")
                    HStack {
                        HotkeyField(hotkey: $workflow.primaryHotkey)
                            .frame(height: 24)
                        Button("⌫") {
                            workflow.primaryHotkey = ""
                        }
                        .buttonStyle(.borderless)
                    }
                }
                VStack {
                    Text("Optional Hotkey 1")
                    HStack {
                        HotkeyField(hotkey: $workflow.optionalHotkey1)
                            .frame(height: 24)
                        Button("⌫") {
                            workflow.optionalHotkey1 = ""
                        }
                        .buttonStyle(.borderless)
                    }
                }
                VStack {
                    Text("Optional Hotkey 2")
                    HStack {
                        HotkeyField(hotkey: $workflow.optionalHotkey2)
                            .frame(height: 24)
                        Button("⌫") {
                            workflow.optionalHotkey2 = ""
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            Picker("Output Method", selection: $workflow.outputMethod) {
                ForEach(OutputMethod.allCases, id: \.self) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Include Screenshot", isOn: $workflow.includeScreenshot)
        }
    }
}

// Main application setup
let app = NSApplication.shared
let delegate = StatusBarController()
app.delegate = delegate
app.run()
