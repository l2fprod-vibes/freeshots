import AppKit
import Observation
import SwiftUI
import UniformTypeIdentifiers
import FreeshotsCore
import FreeshotsRendering

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
                .appAppearance()
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
    var screenshotName = ScreenshotExport.defaultName
    var captureError: String?
    var screenRecordingPermissionMissing = false
    var statusMessage: String?
    var appearance = ScreenshotAppearance.defaults {
        didSet {
            if ProcessInfo.processInfo.environment["FREESHOTS_PREVIEW_EDITOR"] != "1" { persistAppearance() }
        }
    }
    private func persistAppearance() {
        if let data = try? JSONEncoder().encode(appearance) {
            UserDefaults.standard.set(data, forKey: "screenshotAppearance")
        }
    }

    var markup = MarkupDocument()
    private var savedAnnotations: [ScreenshotMark]?
    private var editorPanel: NSPanel?

    private init() {
        if let data = UserDefaults.standard.data(forKey: "screenshotAppearance"),
           let value = try? JSONDecoder().decode(ScreenshotAppearance.self, from: data) { appearance = value }
    }

    func showFloatingEditor() {
        NSApp.unhide(nil)
        NSApp.setActivationPolicy(.regular)
        (NSApp.delegate as? AppDelegate)?.showApplicationMenu()
        NSApp.activate(ignoringOtherApps: true)
        if let editorPanel {
            editorPanel.orderFrontRegardless()
            editorPanel.makeKey()
            return
        }
        let panel = FloatingEditorPanel(
            contentRect: NSRect(x: 0, y: 0, width: KitMetric.editorWidth, height: KitMetric.editorHeight),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = screenshotName
        panel.minSize = NSSize(width: 960, height: 600)
        panel.isFloatingPanel = false
        panel.level = .normal
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.titlebarAppearsTransparent = false
        panel.titleVisibility = .visible
        panel.isReleasedWhenClosed = false
        let content: AnyView = KitGallery.enabled
            ? AnyView(KitGallery())
            : AnyView(ContentView())
        panel.contentView = NSHostingView(rootView: content.environment(self).environment(markup).themed().appAppearance())
        panel.delegate = panel
        panel.shouldCloseHandler = { [weak self] in self?.confirmClose() ?? true }
        panel.didCloseHandler = { [weak self] in self?.editorDidClose(panel) }
        editorPanel = panel
        panel.center()
        panel.orderFrontRegardless()
        panel.makeKey()
    }

    private func editorDidClose(_ panel: FloatingEditorPanel) {
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
            (NSApp.delegate as? AppDelegate)?.hideApplicationMenu()
            NSApp.hide(nil)
        }
    }

    func showLastScreenshot() {
        guard let data = UserDefaults.standard.data(forKey: "lastScreenshot"), let image = NSImage(data: data) else { return }
        screenshot = image
        screenshotName = UserDefaults.standard.string(forKey: "lastScreenshotName") ?? ScreenshotExport.defaultName
        editorPanel?.title = screenshotName
        requestedMode = nil
        markup.reset()
        statusMessage = nil
        showFloatingEditor()
    }

    func openImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "Open"
        let completion: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard response == .OK, let url = panel.url, let image = NSImage(contentsOf: url) else { return }
            guard let self, self.confirmClose() else { return }
            self.screenshot = image
            self.screenshotName = url.deletingPathExtension().lastPathComponent
            self.editorPanel?.title = self.screenshotName
            self.requestedMode = nil
            self.captureError = nil
            self.screenRecordingPermissionMissing = false
            self.statusMessage = nil
            self.savedAnnotations = nil
            self.markup.reset()
            self.showFloatingEditor()
        }
        if let editorPanel, editorPanel.isVisible {
            panel.beginSheetModal(for: editorPanel, completionHandler: completion)
        } else {
            panel.begin(completionHandler: completion)
        }
    }

    func openImageFromClipboard() {
        guard let image = NSImage(pasteboard: .general) else {
            statusMessage = "No image found on the clipboard. Copy an image and try again."
            return
        }
        guard confirmClose() else { return }
        screenshot = image
        screenshotName = "Clipboard Image"
        editorPanel?.title = screenshotName
        requestedMode = nil
        captureError = nil
        screenRecordingPermissionMissing = false
        statusMessage = nil
        savedAnnotations = nil
        markup.reset()
        showFloatingEditor()
    }

    func writePreviewSnapshot(to url: URL) {
        guard let editorPanel, let content = editorPanel.contentView,
              let bitmap = content.bitmapImageRepForCachingDisplay(in: content.bounds) else { return }
        content.cacheDisplay(in: content.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: url, options: .atomic)
        let controls: [(String, NSWindow.ButtonType)] = [("close", .closeButton), ("minimize", .miniaturizeButton), ("zoom", .zoomButton)]
        let report = "bundle=\(Bundle.main.bundleIdentifier ?? "nil")\n" + controls.map { name, type in
            guard let button = editorPanel.standardWindowButton(type) else { return "\(name): missing" }
            return "\(name): hidden=\(button.isHiddenOrHasHiddenAncestor), frame=\(button.frame), parent=\(String(describing: button.superview?.bounds))"
        }.joined(separator: "\n")
        try? report.write(to: url.appendingPathExtension("controls.txt"), atomically: true, encoding: .utf8)
        if let screenshot,
           let export = ScreenshotExport.pngData(from: screenshot, annotations: markup.annotations, appearance: appearance) {
            try? export.write(to: url.appendingPathExtension("rendered.png"), options: .atomic)
        }
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
                let includeWindowShadow = UserDefaults.standard.bool(forKey: "includeWindowShadow")
                guard let image = try await ScreenCaptureService.shared.capture(mode, includeWindowShadow: includeWindowShadow) else {
                    requestedMode = previousMode
                    if wasEditorVisible { showFloatingEditor() }
                    return
                }
                screenshot = image
                screenshotName = mode == .window ? ScreenshotExport.capturedWindowName() : ScreenshotExport.defaultName
                editorPanel?.title = screenshotName
                if (UserDefaults.standard.object(forKey: "rememberLastScreenshot") as? Bool ?? true), let data = image.tiffRepresentation {
                    UserDefaults.standard.set(data, forKey: "lastScreenshot")
                    UserDefaults.standard.set(screenshotName, forKey: "lastScreenshotName")
                }
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
        guard let screenshot, let data = ScreenshotExport.pngData(from: screenshot, annotations: markup.annotations, appearance: appearance) else {
            statusMessage = "Unable to copy screenshot. Try again."
            return
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if pasteboard.setData(data, forType: .png) {
            statusMessage = nil
        } else {
            statusMessage = "Unable to copy screenshot. Try again."
        }
    }

    func saveScreenshot() {
        guard let screenshot, let data = ScreenshotExport.pngData(from: screenshot, annotations: markup.annotations, appearance: appearance) else {
            statusMessage = "Unable to save screenshot. Try again."
            return
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = ScreenshotExport.filename(for: screenshotName)
        panel.canCreateDirectories = true
        let completion: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard response == .OK, let destination = panel.url else { return }
            do {
                try data.write(to: destination, options: .atomic)
                self?.screenshotName = destination.deletingPathExtension().lastPathComponent
                self?.editorPanel?.title = self?.screenshotName ?? destination.lastPathComponent
                self?.savedAnnotations = self?.markup.annotations
                self?.statusMessage = "Saved"
                if UserDefaults.standard.object(forKey: "rememberLastScreenshot") as? Bool ?? true {
                    UserDefaults.standard.set(self?.screenshotName, forKey: "lastScreenshotName")
                }
            } catch {
                self?.statusMessage = "Unable to save screenshot. Choose another location or try again."
            }
        }
        if let editorPanel, editorPanel.isVisible {
            panel.beginSheetModal(for: editorPanel, completionHandler: completion)
        } else {
            panel.begin(completionHandler: completion)
        }
    }

    func openScreenRecordingSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else { return }
        editorPanel?.orderOut(nil)
        NSWorkspace.shared.open(url)
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
    var didCloseHandler: (() -> Void)?

    override func cancelOperation(_ sender: Any?) { close() }

    func windowShouldClose(_ sender: NSWindow) -> Bool { shouldCloseHandler?() ?? true }

    func windowWillClose(_ notification: Notification) { didCloseHandler?() }
}

enum ScreenshotExport {
    static var defaultName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd 'at' h.mm.ss a"
        return "Screenshot \(formatter.string(from: .now))"
    }

    static func filename(for name: String) -> String {
        let cleanName = name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(cleanName.isEmpty ? defaultName : cleanName).png"
    }

    static func capturedWindowName() -> String {
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        guard let window = windows.first(where: {
            ($0[kCGWindowLayer as String] as? Int ?? 1) == 0 &&
            ($0[kCGWindowOwnerPID as String] as? pid_t) != ProcessInfo.processInfo.processIdentifier
        }) else { return defaultName }

        let app = (window[kCGWindowOwnerPID as String] as? pid_t)
            .flatMap(NSRunningApplication.init(processIdentifier:))
        let appWindowTitle = window[kCGWindowName as String] as? String
        let candidate = appWindowTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = candidate.flatMap { $0.isEmpty ? nil : $0 }
        let appName = app?.localizedName?.trimmingCharacters(in: .whitespacesAndNewlines)
        return title ?? appName.flatMap { $0.isEmpty ? nil : $0 } ?? defaultName
    }

    static func pngData(from image: NSImage, annotations: [ScreenshotMark] = [], appearance: ScreenshotAppearance = .defaults) -> Data? {
        ScreenshotRenderer.pngData(image: image, annotations: annotations, appearance: appearance)
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
        Button("Open Image…") { coordinator.openImage() }
            .keyboardShortcut("o", modifiers: .command)
        Button("Open from Clipboard") { coordinator.openImageFromClipboard() }
            .keyboardShortcut("o", modifiers: [.command, .shift])
        Divider()
        Button("Capture Area") { open(.area) }
        Button("Capture Window") { open(.window) }
        Button("Capture Display") { open(.display) }
        if (UserDefaults.standard.object(forKey: "rememberLastScreenshot") as? Bool ?? true), UserDefaults.standard.data(forKey: "lastScreenshot") != nil { Button("Show Last Screenshot") { coordinator.showLastScreenshot() } }
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
    private var permissionWindow: NSWindow?
    private var applicationMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        if ProcessInfo.processInfo.environment["FREESHOTS_PREVIEW_EDITOR"] != "1",
           !CGPreflightScreenCaptureAccess(),
           !UserDefaults.standard.bool(forKey: "permissionOnboardingSkipped") {
            showPermissionOnboarding()
        }
        guard ProcessInfo.processInfo.environment["FREESHOTS_PREVIEW_EDITOR"] == "1" else { return }
        let image = NSImage(size: NSSize(width: 1200, height: 760))
        image.lockFocus()
        NSColor(calibratedRed: 0.94, green: 0.96, blue: 0.98, alpha: 1).setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1200, height: 760)).fill()
        NSColor(calibratedRed: 0.30, green: 0.43, blue: 0.58, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 96, y: 106, width: 1008, height: 548), xRadius: 24, yRadius: 24).fill()
        NSColor.white.withAlphaComponent(0.88).setFill()
        NSBezierPath(roundedRect: NSRect(x: 152, y: 492, width: 896, height: 104), xRadius: 14, yRadius: 14).fill()
        NSBezierPath(roundedRect: NSRect(x: 152, y: 332, width: 430, height: 116), xRadius: 14, yRadius: 14).fill()
        NSBezierPath(roundedRect: NSRect(x: 618, y: 332, width: 430, height: 116), xRadius: 14, yRadius: 14).fill()
        NSBezierPath(roundedRect: NSRect(x: 152, y: 168, width: 896, height: 116), xRadius: 14, yRadius: 14).fill()
        image.unlockFocus()
        CaptureCoordinator.shared.screenshot = image
        if ProcessInfo.processInfo.environment["FREESHOTS_PREVIEW_APPEARANCE"] == "1" {
            CaptureCoordinator.shared.appearance.frame = .window
            CaptureCoordinator.shared.appearance.aspectRatio = .sixteenByNine
        }
        CaptureCoordinator.shared.showFloatingEditor()
        if let snapshotPath = ProcessInfo.processInfo.environment["FREESHOTS_PREVIEW_SNAPSHOT"] {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                CaptureCoordinator.shared.writePreviewSnapshot(to: URL(fileURLWithPath: snapshotPath))
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func showPermissionOnboarding() {
        NSApp.setActivationPolicy(.regular)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Screen Recording Access"
        window.isReleasedWhenClosed = false
        window.contentMinSize = NSSize(width: 500, height: 280)
        window.contentMaxSize = NSSize(width: 500, height: 280)
        window.center()
        let hostingView = NSHostingView(rootView: PermissionOnboardingView(onFinish: { [weak self] skipped in
            if skipped { UserDefaults.standard.set(true, forKey: "permissionOnboardingSkipped") }
            self?.permissionWindow?.close()
            self?.permissionWindow = nil
            NSApp.setActivationPolicy(.accessory)
        }).appAppearance())
        hostingView.sizingOptions = []
        window.contentView = hostingView
        window.setContentSize(NSSize(width: 500, height: 280))
        permissionWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showApplicationMenu() {
        if let applicationMenuItem {
            applicationMenuItem.isHidden = false
            return
        }

        let mainMenu = NSApp.mainMenu ?? NSMenu()
        let appMenuItem = mainMenu.items.first(where: { $0.title == "Freeshots" })
            ?? NSMenuItem(title: "Freeshots", action: nil, keyEquivalent: "")
        let appMenu = NSMenu(title: "Freeshots")
        appMenu.addItem(NSMenuItem(title: "About Freeshots", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Hide Freeshots", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        appMenu.addItem(NSMenuItem(title: "Quit Freeshots", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        if !mainMenu.items.contains(where: { $0 === appMenuItem }) {
            mainMenu.insertItem(appMenuItem, at: 0)
        }
        appMenuItem.isHidden = false
        NSApp.mainMenu = mainMenu
        applicationMenuItem = appMenuItem
    }

    func hideApplicationMenu() {
        applicationMenuItem?.isHidden = true
    }
}

private struct PermissionOnboardingView: View {
    let onFinish: (Bool) -> Void
    @State private var allowed = CGPreflightScreenCaptureAccess()

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: allowed ? "checkmark.shield.fill" : "rectangle.dashed")
                .font(.system(size: 36))
                .foregroundStyle(allowed ? Ink.accentText : Ink.warning)
            Text(allowed ? "Screen Recording is ready" : "Allow Screen Recording")
                .font(.title2.weight(.semibold))
            Text(allowed
                 ? "Freeshots can capture your screen."
                 : "Freeshots needs Screen Recording access to capture your screen. Allow it in System Settings, then return here. This window will continue automatically.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Skip for Now") { onFinish(true) }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                if !allowed {
                    Button("Open System Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Continue") { onFinish(false) }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .task {
            while !Task.isCancelled && !allowed {
                try? await Task.sleep(for: .seconds(1))
                allowed = CGPreflightScreenCaptureAccess()
                if allowed { onFinish(false) }
            }
        }
        .onDisappear { if !allowed { onFinish(true) } }
    }
}
