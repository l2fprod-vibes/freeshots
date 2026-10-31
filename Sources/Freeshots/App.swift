import AppKit
import Observation
import SwiftUI
import UniformTypeIdentifiers

@main
struct FreeshotsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var coordinator = CaptureCoordinator.shared
    @State private var hotkeys = HotkeyCenter.shared

    var body: some Scene {
        MenuBarExtra("Freeshots", systemImage: "viewfinder") {
            CaptureMenu()
                .environment(coordinator)
                .environment(hotkeys)
                .themed()
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environment(hotkeys)
                .themed()
        }
        .windowResizability(.contentSize)
    }
}

@MainActor
@Observable
final class CaptureCoordinator {
    static let shared = CaptureCoordinator()
    var requestedMode: CaptureMode?
    var screenshot: NSImage?
    var captureError: String?
    var screenRecordingPermissionMissing = false
    var statusMessage: String?
    var markup = MarkupDocument()
    private var savedAnnotations: [ScreenshotMark]?
    private var editorPanel: NSPanel?

    func showFloatingEditor() {
        if let editorPanel {
            editorPanel.orderFrontRegardless()
            editorPanel.makeKey()
            return
        }
        let panel = FloatingEditorPanel(
            contentRect: NSRect(x: 0, y: 0, width: KitMetric.editorWidth, height: KitMetric.editorHeight),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = requestedMode?.title ?? "Freeshots"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isReleasedWhenClosed = false
        let content: AnyView = KitGallery.enabled
            ? AnyView(KitGallery())
            : AnyView(ContentView())
        panel.contentView = NSHostingView(rootView: content.environment(self).environment(markup).themed())
        panel.delegate = panel
        panel.shouldCloseHandler = { [weak self] in self?.confirmClose() ?? true }
        editorPanel = panel
        panel.center()
        panel.orderFrontRegardless()
        panel.makeKey()
    }

    func capture(_ mode: CaptureMode, completion: @escaping @MainActor () -> Void) {
        if !markup.annotations.isEmpty, markup.annotations != savedAnnotations, !confirmClose() { return }
        let previousMode = requestedMode
        let wasEditorVisible = editorPanel?.isVisible == true
        editorPanel?.orderOut(nil)
        requestedMode = mode
        captureError = nil
        screenRecordingPermissionMissing = false
        statusMessage = nil
        Task {
            do {
                guard let image = try await ScreenCaptureService.shared.capture(mode) else {
                    requestedMode = previousMode
                    if wasEditorVisible { showFloatingEditor() }
                    return
                }
                screenshot = image
                requestedMode = mode
                captureError = nil
                screenRecordingPermissionMissing = false
                statusMessage = nil
                savedAnnotations = nil
                markup.reset()
                completion()
            } catch ScreenCaptureService.Failure.permissionDenied {
                screenRecordingPermissionMissing = true
                captureError = "Freeshots needs Screen Recording access to capture your screen. Allow it in System Settings, then try again."
                if screenshot == nil {
                    completion()
                } else {
                    requestedMode = previousMode
                    statusMessage = captureError
                    if wasEditorVisible { showFloatingEditor() }
                }
            } catch {
                let message = "Unable to capture the screen. Check Screen Recording access and try again."
                if screenshot == nil {
                    captureError = message
                    completion()
                } else {
                    requestedMode = previousMode
                    statusMessage = message
                    if wasEditorVisible { showFloatingEditor() }
                }
            }
        }
    }

    func copyScreenshot() {
        guard let screenshot, let data = ScreenshotExport.pngData(from: screenshot, annotations: markup.annotations) else {
            statusMessage = "Unable to copy screenshot. Try again."
            return
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if pasteboard.setData(data, forType: .png) {
            statusMessage = "Copied"
        } else {
            statusMessage = "Unable to copy screenshot. Try again."
        }
    }

    func saveScreenshot() {
        guard let screenshot, let data = ScreenshotExport.pngData(from: screenshot, annotations: markup.annotations) else {
            statusMessage = "Unable to save screenshot. Try again."
            return
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = ScreenshotExport.suggestedFilename
        panel.canCreateDirectories = true
        panel.begin { [weak self] response in
            guard response == .OK, let destination = panel.url else { return }
            do {
                try data.write(to: destination, options: .atomic)
                self?.savedAnnotations = self?.markup.annotations
                self?.statusMessage = "Saved"
            } catch {
                self?.statusMessage = "Unable to save screenshot. Choose another location or try again."
            }
        }
    }

    private func confirmClose() -> Bool {
        guard !markup.annotations.isEmpty, markup.annotations != savedAnnotations else { return true }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Discard your markup?"
        alert.informativeText = "Your unsaved markup will be lost."
        alert.addButton(withTitle: "Discard Changes")
        alert.addButton(withTitle: "Keep Editing")
        return alert.runModal() == .alertFirstButtonReturn
    }
}

private final class FloatingEditorPanel: NSPanel, NSWindowDelegate {
    var shouldCloseHandler: (() -> Bool)?

    override func cancelOperation(_ sender: Any?) { close() }

    func windowShouldClose(_ sender: NSWindow) -> Bool { shouldCloseHandler?() ?? true }
}

enum ScreenshotExport {
    static var suggestedFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return "Freeshots \(formatter.string(from: .now)).png"
    }

    static func pngData(from image: NSImage, annotations: [ScreenshotMark] = []) -> Data? {
        ScreenshotRenderer.pngData(image: image, annotations: annotations)
    }
}

enum CaptureMode: CaseIterable, Identifiable {
    case area
    case window
    case display

    var title: String {
        switch self {
        case .area: "Capture Area"
        case .window: "Capture Window"
        case .display: "Capture Display"
        }
    }

    var id: Self { self }
}

private struct CaptureMenu: View {
    @Environment(CaptureCoordinator.self) private var coordinator
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        menuContent
    }

    @ViewBuilder
    private var menuContent: some View {
        Button("Capture Area") { open(.area) }
        Button("Capture Window") { open(.window) }
        Button("Capture Display") { open(.display) }
        Divider()
        Button("Settings…") { openSettings() }
            .keyboardShortcut(",", modifiers: .command)
        Divider()
        Button("Quit") { NSApp.terminate(nil) }
            .keyboardShortcut("q", modifiers: .command)
    }

    private func open(_ mode: CaptureMode) {
        coordinator.capture(mode) { coordinator.showFloatingEditor() }
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
