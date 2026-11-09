import AppKit

@MainActor
final class ScreenCaptureService {
    static let shared = ScreenCaptureService()
    private init() {}

    func capture(
        _ mode: CaptureMode,
        includeWindowShadow: Bool,
        targetScreen: NSScreen? = nil,
        delaySeconds: Int = 0,
        onInteractiveSelection: (@MainActor () async -> Bool)? = nil
    ) async throws -> NSImage? {
        guard CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess() else {
            throw Failure.permissionDenied
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Freeshots-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: url) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        var arguments: [String]
        switch mode {
        case .area:
            arguments = ["-i", "-s", "-x"]
        case .window:
            arguments = ["-i", "-w", "-x"]
            if !includeWindowShadow { arguments.append("-o") }
        case .display:
            let pointer = NSEvent.mouseLocation
            let displayIndex = targetScreen.flatMap { NSScreen.screens.firstIndex(of: $0) }
                ?? NSScreen.screens.firstIndex { $0.frame.contains(pointer) }
                ?? 0
            arguments = ["-x", "-D", "\(displayIndex + 1)"]
        }
        if delaySeconds > 0 {
            arguments.append(contentsOf: ["-T", "\(delaySeconds)"])
        }
        arguments.append(url.path)
        process.arguments = arguments

        var selectionWasCancelled = false
        var countdownTask: Task<Void, Never>?
        let selectionWatcher: InteractiveSelectionWatcher? = delaySeconds > 0 && onInteractiveSelection != nil
            ? InteractiveSelectionWatcher()
            : nil
        selectionWatcher?.start {
            countdownTask = Task { @MainActor in
                guard let onInteractiveSelection else { return }
                if !(await onInteractiveSelection()) {
                    selectionWasCancelled = true
                    if process.isRunning { process.terminate() }
                }
            }
        }
        defer {
            selectionWatcher?.stop()
            countdownTask?.cancel()
        }

        let status = try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { process in
                continuation.resume(returning: process.terminationStatus)
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
        if selectionWasCancelled { return nil }
        guard status == 0 else { throw Failure.commandFailed }
        return NSImage(contentsOf: url)
    }

    enum Failure: Error {
        case permissionDenied
        case commandFailed
    }
}

@MainActor
private final class InteractiveSelectionWatcher {
    private var timer: Timer?
    private var lastMouseUpCount: UInt32 = 0
    private var handler: (@MainActor () -> Void)?

    func start(handler: @escaping @MainActor () -> Void) {
        self.handler = handler
        lastMouseUpCount = CGEventSource.counterForEventType(
            .combinedSessionState,
            eventType: .leftMouseUp
        )
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.pollMouseUp() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        handler = nil
    }

    private func pollMouseUp() {
        let mouseUpCount = CGEventSource.counterForEventType(
            .combinedSessionState,
            eventType: .leftMouseUp
        )
        guard mouseUpCount != lastMouseUpCount else { return }
        lastMouseUpCount = mouseUpCount
        guard let handler else { return }
        stop()
        handler()
    }
}
