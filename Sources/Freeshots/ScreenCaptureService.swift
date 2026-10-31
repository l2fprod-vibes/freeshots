import AppKit

@MainActor
final class ScreenCaptureService {
    static let shared = ScreenCaptureService()
    private init() {}

    func capture(_ mode: CaptureMode) async throws -> NSImage? {
        guard CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess() else {
            throw Failure.permissionDenied
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Freeshots-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: url) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        switch mode {
        case .area:
            process.arguments = ["-i", "-s", "-x", url.path]
        case .window:
            process.arguments = ["-i", "-w", "-x", url.path]
        case .display:
            let pointer = NSEvent.mouseLocation
            let displayIndex = NSScreen.screens.firstIndex { $0.frame.contains(pointer) } ?? 0
            process.arguments = ["-x", "-D", "\(displayIndex + 1)", url.path]
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
        guard status == 0 else { throw Failure.commandFailed }
        return NSImage(contentsOf: url)
    }

    enum Failure: Error {
        case permissionDenied
        case commandFailed
    }
}
