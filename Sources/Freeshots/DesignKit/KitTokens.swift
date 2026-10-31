import AppKit
import SwiftUI

/// Raw colors live here. Components read only the semantic `Ink` layer.
private enum Palette {
    static let canvasLight: UInt32 = 0xF1F3F5
    static let canvasDark: UInt32 = 0x171A1F
    static let surfaceLight: UInt32 = 0xFFFFFF
    static let surfaceDark: UInt32 = 0x232830
    static let textLight: UInt32 = 0x20252C
    static let textDark: UInt32 = 0xF4F6F8
    static let mutedLight: UInt32 = 0x66717C
    static let mutedDark: UInt32 = 0xA1AAB4
    static let lime: UInt32 = 0xD6FF4F
    static let limeTextLight: UInt32 = 0x435800
    static let onLime: UInt32 = 0x1A2109
    static let selectionLight: UInt32 = 0xEDF7C6
    static let selectionDark: UInt32 = 0x394820
    static let dividerLight: UInt32 = 0xDDE2E6
    static let dividerDark: UInt32 = 0x383E47
    static let warningLight: UInt32 = 0xA83D32
    static let warningDark: UInt32 = 0xFF877B
}

enum Ink {
    static let canvas = Color(light: Palette.canvasLight, dark: Palette.canvasDark)
    static let surface = Color(light: Palette.surfaceLight, dark: Palette.surfaceDark)
    static let text = Color(light: Palette.textLight, dark: Palette.textDark)
    static let muted = Color(light: Palette.mutedLight, dark: Palette.mutedDark)
    static let accent = Color(hex: Palette.lime)
    static let accentText = Color(light: Palette.limeTextLight, dark: Palette.lime)
    static let onAccent = Color(hex: Palette.onLime)
    static let selection = Color(light: Palette.selectionLight, dark: Palette.selectionDark)
    static let divider = Color(light: Palette.dividerLight, dark: Palette.dividerDark)
    static let warning = Color(light: Palette.warningLight, dark: Palette.warningDark)
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

extension Color {
    fileprivate init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    fileprivate init(light: UInt32, dark: UInt32) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [.aqua, .darkAqua])
            let value = match == .darkAqua ? dark : light
            return NSColor(calibratedRed: CGFloat((value >> 16) & 0xFF) / 255,
                           green: CGFloat((value >> 8) & 0xFF) / 255,
                           blue: CGFloat(value & 0xFF) / 255,
                           alpha: 1)
        })
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
