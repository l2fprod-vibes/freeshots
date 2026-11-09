import AppKit
import Observation
import SwiftUI

@MainActor
final class CaptureCountdownOverlay {
    static let shared = CaptureCountdownOverlay()
    private var previewPanel: CountdownPanel?

    private init() {}

    func run(on screen: NSScreen, seconds: Int = 5) async -> Bool {
        let state = CountdownOverlayState(secondsRemaining: seconds)
        let panel = makePanel(state: state, screen: screen)
        panel.orderFrontRegardless()
        panel.makeKey()
        announceCountdown(on: panel, seconds: seconds)

        defer { panel.close() }
        for remaining in stride(from: seconds, through: 1, by: -1) {
            state.secondsRemaining = remaining
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return false
            }
            if state.isCancelled { return false }
        }
        return !state.isCancelled
    }

    func showPreview(on screen: NSScreen) {
        let state = CountdownOverlayState(secondsRemaining: 5)
        let panel = makePanel(state: state, screen: screen, shareableForPreview: true)
        previewPanel = panel
        panel.orderFrontRegardless()
        panel.makeKey()
        announceCountdown(on: panel, seconds: 5)
    }

    private func makePanel(state: CountdownOverlayState, screen: NSScreen, shareableForPreview: Bool = false) -> CountdownPanel {
        let panel = CountdownPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: KitMetric.countdownOverlayWidth,
                height: KitMetric.countdownOverlayHeight
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Capture Countdown"
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.sharingType = shareableForPreview ? .readOnly : .none
        panel.contentView = NSHostingView(rootView: CountdownOverlayView(state: state))
        panel.centerOnScreen(screen)
        return panel
    }

    private func announceCountdown(on panel: NSPanel, seconds: Int) {
        NSAccessibility.post(
            element: panel,
            notification: .announcementRequested,
            userInfo: [.announcement: "Screenshot in \(seconds) seconds. Press Escape to cancel."]
        )
    }
}

@MainActor
private final class CountdownPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func centerOnScreen(_ screen: NSScreen) {
        let origin = NSPoint(
            x: screen.visibleFrame.midX - frame.width / 2,
            y: screen.visibleFrame.midY - frame.height / 2
        )
        setFrameOrigin(origin)
    }
}

@MainActor
@Observable
private final class CountdownOverlayState {
    var secondsRemaining: Int
    var isCancelled = false

    init(secondsRemaining: Int) {
        self.secondsRemaining = secondsRemaining
    }

    func cancel() {
        isCancelled = true
    }
}

private struct CountdownOverlayView: View {
    @State private var state: CountdownOverlayState
    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(state: CountdownOverlayState) {
        _state = State(initialValue: state)
    }

    var body: some View {
        VStack(spacing: 8) {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
                let phase = context.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: KitMotion.countdownRevolution)
                ZStack {
                    Circle()
                        .stroke(.primary.opacity(0.12), lineWidth: KitMetric.countdownTrackWidth)
                    Circle()
                        .trim(from: 0, to: 0.22)
                        .stroke(.primary, style: StrokeStyle(lineWidth: KitMetric.countdownRingWidth, lineCap: .round))
                        .rotationEffect(.degrees(phase / KitMotion.countdownRevolution * 360 - 90))
                    Text("\(state.secondsRemaining)")
                        .font(.system(size: KitMetric.countdownNumberSize, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .accessibilityLabel("Screenshot countdown")
                }
                .frame(width: KitMetric.countdownDialSize, height: KitMetric.countdownDialSize)
            }

            Text("Screenshot in \(state.secondsRemaining) seconds")
                .font(.headline)
                .accessibilityHidden(true)

            Button("Cancel") { state.cancel() }
                .buttonStyle(.borderless)
                .keyboardShortcut(.cancelAction)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: KitMetric.panelRadius))
        .overlay {
            RoundedRectangle(cornerRadius: KitMetric.panelRadius)
                .strokeBorder(.primary.opacity(0.12), lineWidth: 1)
        }
        .padding(KitMetric.controlRadius)
        .focusable()
        .focused($isFocused)
        .onKeyPress(.escape) {
            state.cancel()
            return .handled
        }
        .onAppear { isFocused = true }
        .accessibilityElement(children: .contain)
    }
}
