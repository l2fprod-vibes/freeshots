import SwiftUI

/// Freeshots follows the accent color selected in macOS.
enum ThemeStore {
    static let defaultID = "system"
}

enum NativeTheme {
    static let accent = Color.accentColor
}

extension View {
    func themed() -> some View {
        tint(NativeTheme.accent)
    }
}
