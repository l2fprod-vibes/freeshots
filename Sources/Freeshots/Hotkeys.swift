import Carbon.HIToolbox
import Observation
import SwiftUI

struct ShortcutBinding: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    var label: String {
        var parts: [String] = []
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        parts.append(Self.keyLabels[keyCode] ?? "Key \(keyCode)")
        return parts.joined()
    }

    static let defaults: [CaptureMode: ShortcutBinding] = [
        .area: .init(keyCode: UInt32(kVK_ANSI_1), modifiers: UInt32(cmdKey | optionKey | controlKey)),
        .window: .init(keyCode: UInt32(kVK_ANSI_2), modifiers: UInt32(cmdKey | optionKey | controlKey)),
        .display: .init(keyCode: UInt32(kVK_ANSI_3), modifiers: UInt32(cmdKey | optionKey | controlKey)),
    ]

    private static let keyLabels: [UInt32: String] = [
        UInt32(kVK_ANSI_1): "1", UInt32(kVK_ANSI_2): "2", UInt32(kVK_ANSI_3): "3",
        UInt32(kVK_ANSI_4): "4", UInt32(kVK_ANSI_5): "5", UInt32(kVK_ANSI_6): "6",
        UInt32(kVK_ANSI_7): "7", UInt32(kVK_ANSI_8): "8", UInt32(kVK_ANSI_9): "9",
        UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B", UInt32(kVK_ANSI_C): "C",
        UInt32(kVK_ANSI_D): "D", UInt32(kVK_ANSI_E): "E", UInt32(kVK_ANSI_F): "F",
        UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H", UInt32(kVK_ANSI_I): "I",
        UInt32(kVK_ANSI_J): "J", UInt32(kVK_ANSI_K): "K", UInt32(kVK_ANSI_L): "L",
        UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N", UInt32(kVK_ANSI_O): "O",
        UInt32(kVK_ANSI_P): "P", UInt32(kVK_ANSI_Q): "Q", UInt32(kVK_ANSI_R): "R",
        UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T", UInt32(kVK_ANSI_U): "U",
        UInt32(kVK_ANSI_V): "V", UInt32(kVK_ANSI_W): "W", UInt32(kVK_ANSI_X): "X",
        UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z",
        UInt32(kVK_Space): "Space",
    ]
}

@MainActor
@Observable
final class HotkeyCenter {
    static let shared = HotkeyCenter()
    private(set) var bindings = ShortcutBinding.defaults
    private(set) var errors: [CaptureMode: String] = [:]
    var onCapture: (@MainActor (CaptureMode) -> Void)?

    private var references: [CaptureMode: EventHotKeyRef] = [:]
    private var handler: EventHandlerRef?
    private let defaultsKey = "captureShortcuts"

    private init() {
        onCapture = { mode in
            let coordinator = CaptureCoordinator.shared
            coordinator.capture(mode) { coordinator.showFloatingEditor() }
        }
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let saved = try? JSONDecoder().decode([String: ShortcutBinding].self, from: data) {
            for mode in CaptureMode.allCases {
                if let binding = saved[mode.storageKey] { bindings[mode] = binding }
            }
        }
        installHandler()
        for mode in CaptureMode.allCases where !register(mode, binding: bindings[mode]!) {
            errors[mode] = "Shortcut already in use. Choose another combination."
        }
    }

    func set(_ binding: ShortcutBinding, for mode: CaptureMode) {
        errors[mode] = nil
        if CaptureMode.allCases.contains(where: { $0 != mode && bindings[$0] == binding }) {
            errors[mode] = "Shortcut already in use by another capture mode."
            return
        }

        unregister(mode)
        guard register(mode, binding: binding) else {
            errors[mode] = "Shortcut already in use. Choose a different key combination."
            _ = register(mode, binding: bindings[mode]!)
            return
        }
        bindings[mode] = binding
        persist()
    }

    func restoreDefaults() {
        errors.removeAll()
        for mode in CaptureMode.allCases {
            unregister(mode)
            let binding = ShortcutBinding.defaults[mode]!
            guard register(mode, binding: binding) else {
                errors[mode] = "Default shortcut already in use. Choose another combination."
                continue
            }
            bindings[mode] = binding
        }
        persist()
    }

    func fire(_ identifier: UInt32) {
        guard let mode = CaptureMode(rawIdentifier: identifier) else { return }
        onCapture?(mode)
    }

    private func register(_ mode: CaptureMode, binding: ShortcutBinding) -> Bool {
        var reference: EventHotKeyRef?
        let id = EventHotKeyID(signature: OSType(0x46524545), id: mode.identifier)
        let status = RegisterEventHotKey(binding.keyCode, binding.modifiers, id,
                                         GetApplicationEventTarget(), 0, &reference)
        guard status == noErr, let reference else { return false }
        references[mode] = reference
        return true
    }

    private func unregister(_ mode: CaptureMode) {
        if let reference = references.removeValue(forKey: mode) { UnregisterEventHotKey(reference) }
    }

    private func installHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var id = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID), nil,
                                           MemoryLayout<EventHotKeyID>.size, nil, &id)
            if status == noErr { Task { @MainActor in HotkeyCenter.shared.fire(UInt32(id.id)) } }
            return noErr
        }, 1, &eventType, nil, &handler)
    }

    private func persist() {
        let encoded = Dictionary(uniqueKeysWithValues: bindings.map { ($0.key.storageKey, $0.value) })
        guard let data = try? JSONEncoder().encode(encoded) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}

private extension CaptureMode {
    var identifier: UInt32 {
        switch self { case .area: 1; case .window: 2; case .display: 3 }
    }
    var storageKey: String {
        switch self { case .area: "area"; case .window: "window"; case .display: "display" }
    }
    init?(rawIdentifier: UInt32) {
        switch rawIdentifier {
        case 1: self = .area
        case 2: self = .window
        case 3: self = .display
        default: return nil
        }
    }
}

struct ShortcutCaptureField: NSViewRepresentable {
    var isRecording: Bool
    var binding: ShortcutBinding
    var onChange: (ShortcutBinding) -> Void
    var onCancel: () -> Void

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.onChange = onChange
        view.onCancel = onCancel
        view.binding = binding
        view.isRecording = isRecording
        return view
    }

    func updateNSView(_ view: ShortcutRecorderNSView, context: Context) {
        view.onChange = onChange
        view.onCancel = onCancel
        view.binding = binding
        view.isRecording = isRecording
        if isRecording, view.window?.firstResponder !== view { view.window?.makeFirstResponder(view) }
        view.needsDisplay = true
    }
}

final class ShortcutRecorderNSView: NSView {
    var isRecording = false
    var binding = ShortcutBinding.defaults[.area]!
    var onChange: ((ShortcutBinding) -> Void)?
    var onCancel: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }
    override func accessibilityLabel() -> String? { "Capture shortcut" }
    override func accessibilityValue() -> Any? { isRecording ? "Type shortcut" : binding.label }
    override func accessibilityHelp() -> String? { "Press a modifier and key combination. Press Escape to cancel." }
    override func mouseDown(with event: NSEvent) { window?.makeFirstResponder(self) }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { super.keyDown(with: event); return }
        if event.keyCode == UInt16(kVK_Escape) { onCancel?(); return }
        let allowed: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
        let flags = event.modifierFlags.intersection(allowed)
        let modifiers = (flags.contains(.command) ? UInt32(cmdKey) : 0)
            | (flags.contains(.option) ? UInt32(optionKey) : 0)
            | (flags.contains(.control) ? UInt32(controlKey) : 0)
            | (flags.contains(.shift) ? UInt32(shiftKey) : 0)
        guard modifiers != 0 else { NSSound.beep(); return }
        onChange?(ShortcutBinding(keyCode: UInt32(event.keyCode), modifiers: modifiers))
    }

    override func draw(_ dirtyRect: NSRect) {
        let text = isRecording ? "Type shortcut…" : binding.label
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: isRecording ? NSColor.controlAccentColor : NSColor.labelColor,
            .paragraphStyle: paragraph,
        ]
        (text as NSString).draw(in: bounds.insetBy(dx: 6, dy: 5), withAttributes: attributes)
    }
}
