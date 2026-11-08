import SwiftUI

struct KitActionButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, ghost }
    var kind: Kind = .primary

    func makeBody(configuration: Configuration) -> some View {
        KitActionButtonBody(configuration: configuration, kind: kind)
    }
}

extension ButtonStyle where Self == KitActionButtonStyle {
    static func kit(_ kind: KitActionButtonStyle.Kind = .primary) -> KitActionButtonStyle {
        KitActionButtonStyle(kind: kind)
    }
}

private struct KitActionButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let kind: KitActionButtonStyle.Kind
    @Environment(\.forcedPartState) private var forced
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @State private var hovering = false

    private var state: PartState {
        forced ?? (!isEnabled ? .disabled : configuration.isPressed ? .pressed : hovering ? .hover : isFocused ? .focused : .rest)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: KitMetric.controlRadius, style: .continuous)
        configuration.label
            .kitType(.labelStrong)
            .padding(.horizontal, 12)
            .frame(height: KitMetric.actionHeight)
            .foregroundStyle(foreground)
            .background(fill, in: shape)
            .focusEffectDisabled()
            .scaleEffect(state == .pressed ? 0.98 : 1)
            .opacity(state == .disabled ? 0.4 : 1)
            .contentShape(shape)
            .onHover { hovering = $0 }
            .animation(KitMotion.press, value: state)
    }

    private var foreground: Color {
        kind == .primary ? Ink.onAccent : Ink.text
    }

    private var fill: Color {
        switch kind {
        case .primary: Ink.accent.opacity(state == .hover ? 0.92 : state == .pressed ? 0.82 : 1)
        case .secondary: state == .hover || state == .pressed ? Ink.selection : Ink.surface
        case .ghost: state == .hover || state == .pressed ? Ink.selection : .clear
        }
    }
}

struct KitToolButtonStyle: ButtonStyle {
    var selected = false

    func makeBody(configuration: Configuration) -> some View {
        KitToolButtonBody(configuration: configuration, selected: selected)
    }
}

private struct KitToolButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let selected: Bool
    @Environment(\.forcedPartState) private var forced
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @State private var hovering = false

    private var state: PartState {
        forced ?? (!isEnabled ? .disabled : configuration.isPressed ? .pressed : selected ? .selected : hovering ? .hover : isFocused ? .focused : .rest)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: KitMetric.controlRadius, style: .continuous)
        configuration.label
            .foregroundStyle(state == .selected ? Ink.selectionText : Ink.text)
            .frame(width: KitMetric.toolSize, height: KitMetric.toolSize)
            .background(fill, in: shape)
            .focusEffectDisabled()
            .scaleEffect(state == .pressed ? 0.97 : 1)
            .opacity(state == .disabled ? 0.4 : 1)
            .contentShape(shape)
            .onHover { hovering = $0 }
            .animation(KitMotion.hover, value: state)
    }

    private var fill: Color {
        switch state {
        case .selected: Ink.selection
        case .hover, .pressed: Ink.selection.opacity(0.72)
        default: .clear
        }
    }
}

struct KitToolButton: View {
    let icon: KitIcon
    let title: String
    let shortcut: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            KitIconView(icon: icon)
        }
        .buttonStyle(KitToolButtonStyle(selected: selected))
        .help("\(title) (\(shortcut))")
        .accessibilityLabel(title)
    }
}

// Popup rows draw hover feedback themselves rather than using native button chrome.
struct KitPopupButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        KitPopupButtonBody(configuration: configuration)
    }
}

private struct KitPopupButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @State private var hovering = false

    var body: some View {
        configuration.label
            .foregroundStyle(Ink.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(hovering || configuration.isPressed ? Ink.selection : .clear,
                        in: RoundedRectangle(cornerRadius: KitMetric.controlRadius))
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
            .focusEffectDisabled()
    }
}
