import AppKit
import SwiftUI

/// Use semantic AppKit colors so the editor follows macOS appearance and accent settings.
enum Ink {
    static let canvas = Color(nsColor: .windowBackgroundColor)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let text = Color.primary
    static let muted = Color.secondary
    static let accent = Color.accentColor
    static let accentText = Color.accentColor
    static let onAccent = Color.primary
    static let selection = Color(nsColor: .selectedContentBackgroundColor)
    static let selectionText = Color(nsColor: .selectedMenuItemTextColor)
    static let divider = Color(nsColor: .separatorColor)
    static let warning = Color(nsColor: .systemRed)
}

enum KitMetric {
    static let toolSize: CGFloat = 30
    static let actionHeight: CGFloat = 32
    static let controlRadius: CGFloat = 10
    static let panelRadius: CGFloat = 18
    static let editorWidth: CGFloat = 1120
    static let editorHeight: CGFloat = 720
}

enum KitMotion {
    static let hover = Animation.easeOut(duration: 0.12)
    static let press = Animation.spring(response: 0.20, dampingFraction: 0.78)
}

enum KitType {
    case title, body, label, labelStrong, meta

    var font: Font {
        switch self {
        case .title: .system(size: 20, weight: .semibold)
        case .body: .system(size: 13)
        case .label: .system(size: 13)
        case .labelStrong: .system(size: 13, weight: .semibold)
        case .meta: .system(size: 11)
        }
    }
}

extension View {
    func kitType(_ role: KitType) -> some View {
        font(role.font)
    }
}

enum PartState: String, CaseIterable {
    case rest, hover, pressed, selected, focused, disabled
}

private struct ForcedPartStateKey: EnvironmentKey {
    static let defaultValue: PartState? = nil
}

extension EnvironmentValues {
    var forcedPartState: PartState? {
        get { self[ForcedPartStateKey.self] }
        set { self[ForcedPartStateKey.self] = newValue }
    }
}
