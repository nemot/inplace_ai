import Cocoa
import SwiftUI

// Hotkey Field
struct HotkeyField: NSViewRepresentable {
    @Binding var hotkey: String

    func makeNSView(context: Context) -> NSView {
        let view = HotkeyView()
        view.hotkey = hotkey
        view.onHotkeyChange = { newHotkey in
            self.hotkey = newHotkey
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? HotkeyView {
            view.hotkey = hotkey
        }
    }
}

class HotkeyView: NSView {
    var hotkey: String = "" {
        didSet {
            textField.stringValue = formatHotkey(hotkey)
        }
    }

    var onHotkeyChange: ((String) -> Void)?

    let textField = NSTextField()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    func setup() {
        textField.frame = bounds
        textField.autoresizingMask = [.width, .height]
        textField.isEditable = false
        textField.isSelectable = false
        textField.placeholderString = "Click to set hotkey"
        textField.alignment = .center
        addSubview(textField)
    }

    override func becomeFirstResponder() -> Bool {
        textField.backgroundColor = NSColor.selectedControlColor
        return super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        textField.backgroundColor = NSColor.controlBackgroundColor
        return super.resignFirstResponder()
    }

    override func keyDown(with event: NSEvent) {
        var parts: [String] = []
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if modifiers.contains(.command) { parts.append("command") }
        if modifiers.contains(.option) { parts.append("option") }
        if modifiers.contains(.control) { parts.append("control") }
        if modifiers.contains(.shift) { parts.append("shift") }

        if let chars = event.charactersIgnoringModifiers?.uppercased(), !chars.isEmpty {
            parts.append(chars)
        }

        let newHotkey = parts.joined(separator: "+")
        if !newHotkey.isEmpty {
            hotkey = newHotkey
            onHotkeyChange?(newHotkey)
        }
    }

    func formatHotkey(_ hk: String) -> String {
        return hk.replacingOccurrences(of: "command", with: "⌘")
            .replacingOccurrences(of: "option", with: "⌥")
            .replacingOccurrences(of: "control", with: "⌃")
            .replacingOccurrences(of: "shift", with: "⇧")
    }
}
