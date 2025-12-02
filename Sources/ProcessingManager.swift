import Cocoa
import CoreGraphics

class ProcessingManager {
    static let shared = ProcessingManager()

    private var originalClipboard: String = ""

    func processWorkflow(_ workflow: Workflow, statusController: StatusBarController) async {
        Log.processing.info("Starting processing for workflow: \(workflow.name)")

        // Change icon to spinner
        statusController.setProcessing(true)

        defer {
            statusController.setProcessing(false)
        }

        guard !workflow.token.isEmpty else {
            Log.processing.error("No API token set for workflow")
            return
        }

        do {
            // Save original clipboard
            originalClipboard = getClipboardContent()

            // Simulate Cmd+C
            simulateKeyPress(keyCode: 8, modifiers: .maskCommand) // 8 is 'c'

            // Wait a bit for clipboard to update
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1s

            // Get selected text
            let selectedText = getClipboardContent()
            if selectedText.isEmpty {
                Log.processing.error("No text selected")
                restoreClipboard()
                return
            }

            Log.processing.info("Selected text: \(selectedText)")

            // Replace {text} in prompt
            let prompt = workflow.prompt.replacingOccurrences(of: "{text}", with: selectedText)

            // Call API
            let response = try await APIClient.shared.sendChatRequest(provider: workflow.provider, model: workflow.model, prompt: prompt, apiKey: workflow.token)
            Log.processing.info("API response: \(response)")

            // Clean response
            let cleanedResponse = cleanResponse(response)

            // Set to clipboard
            setClipboardContent(cleanedResponse)

            // Output
            switch workflow.outputMethod {
            case .pasteInPlace:
                // Simulate Cmd+V
                simulateKeyPress(keyCode: 9, modifiers: .maskCommand) // 9 is 'v'
            case .banner:
                showBanner(text: cleanedResponse)
            }

            // Restore original clipboard after a delay
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            restoreClipboard()

            Log.processing.info("Processing completed")

        } catch {
            Log.processing.error("Processing error: \(error.localizedDescription)")
            restoreClipboard()
        }
    }

    private func getClipboardContent() -> String {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string) ?? ""
    }

    private func setClipboardContent(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }

    private func restoreClipboard() {
        setClipboardContent(originalClipboard)
    }

    private func simulateKeyPress(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)

        keyDown?.flags = modifiers
        keyUp?.flags = modifiers

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    private func cleanResponse(_ response: String) -> String {
        // Remove <thinking> tags or similar
        let cleaned = response.replacingOccurrences(of: "<thinking>.*?</thinking>", with: "", options: .regularExpression)
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func showBanner(text: String) {
        DispatchQueue.main.async {
            let banner = BannerWindow(text: text)
            banner.show()
        }
    }
}

class BannerWindow: NSWindow {
    init(text: String) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
                   styleMask: [.titled, .closable, .resizable],
                   backing: .buffered,
                   defer: false)

        self.title = "AI Response"
        self.level = .floating
        self.isReleasedWhenClosed = false

        let contentBounds = self.contentView!.bounds
        let insetRect = contentBounds.insetBy(dx: 10, dy: 10)
        let scrollView = NSScrollView(frame: insetRect)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autoresizingMask = [.width, .height]

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height))
        textView.string = text
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.autoresizingMask = [.width, .height]

        scrollView.documentView = textView
        self.contentView?.addSubview(scrollView)

        self.center()
    }

    func show() {
        self.makeKeyAndOrderFront(nil)
    }
}
