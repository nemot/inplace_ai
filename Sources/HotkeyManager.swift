import Cocoa

class HotkeyManager {
    static let shared = HotkeyManager()

    private var monitors: [Any] = []
    private var workflowHandlers: [String: (Workflow) -> Void] = [:]

    func registerHotkeys(for workflows: [Workflow], handler: @escaping (Workflow) -> Void) {
        unregisterAll()
        for workflow in workflows {
            let hotkeys = [workflow.primaryHotkey, workflow.optionalHotkey1, workflow.optionalHotkey2].filter { !$0.isEmpty }
            for hotkey in hotkeys {
                if let (modifiers, keyCode) = parseHotkey(hotkey) {
                    let monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
                        if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == modifiers &&
                           event.keyCode == keyCode {
                            handler(workflow)
                        }
                    }
                    monitors.append(monitor as Any)
                    workflowHandlers[hotkey] = handler
                }
            }
        }
    }

    func unregisterAll() {
        monitors.forEach { NSEvent.removeMonitor($0) }
        monitors.removeAll()
        workflowHandlers.removeAll()
    }

    private func parseHotkey(_ hotkey: String) -> (NSEvent.ModifierFlags, UInt16)? {
        let parts = hotkey.lowercased().split(separator: "+").map { String($0) }
        var modifiers: NSEvent.ModifierFlags = []
        var keyCode: UInt16?

        for part in parts {
            switch part {
            case "command", "cmd", "⌘":
                modifiers.insert(.command)
            case "option", "alt", "⌥":
                modifiers.insert(.option)
            case "control", "ctrl", "⌃":
                modifiers.insert(.control)
            case "shift", "⇧":
                modifiers.insert(.shift)
            default:
                if let code = keyCodeForString(part) {
                    keyCode = code
                }
            }
        }

        guard let code = keyCode else { return nil }
        return (modifiers, code)
    }

    private func keyCodeForString(_ string: String) -> UInt16? {
        let keyMap: [String: UInt16] = [
            "A": 0, "B": 11, "C": 8, "D": 2, "E": 14, "F": 3, "G": 5, "H": 4, "I": 34, "J": 38, "K": 40, "L": 37, "M": 46, "N": 45, "O": 31, "P": 35, "Q": 12, "R": 15, "S": 1, "T": 17, "U": 32, "V": 9, "W": 13, "X": 7, "Y": 16, "Z": 6,
            "0": 29, "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22, "7": 26, "8": 28, "9": 25,
            " ": 49, "-": 27, "=": 24, "[": 33, "]": 30, "\\": 42, ";": 41, "'": 39, ",": 43, ".": 47, "/": 44, "`": 50
        ]
        return keyMap[string.uppercased()]
    }
}
