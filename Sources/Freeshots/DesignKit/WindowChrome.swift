import AppKit
import SwiftUI

struct WindowChrome: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = ChromeView()
        view.configure = configure
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private func configure(_ window: NSWindow) {
        window.level = .floating
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
    }

    private final class ChromeView: NSView {
        var configure: ((NSWindow) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            DispatchQueue.main.async { [weak self] in self?.configure?(window) }
        }
    }
}
