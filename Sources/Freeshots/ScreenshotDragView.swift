import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DragToSaveControl: View {
    let dataProvider: @MainActor () -> Data?
    let filename: String
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 7) {
            VStack(spacing: 3) {
                ForEach(0..<3) { _ in
                    HStack(spacing: 3) {
                        Circle().fill(Ink.muted)
                        Circle().fill(Ink.muted)
                    }
                    .frame(width: 8, height: 3)
                }
            }
            .accessibilityHidden(true)
            Text("Drag to Save")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Ink.text)
                .fixedSize()
        }
        .padding(.horizontal, 9)
        .frame(height: KitMetric.toolSize)
        .background(
            isHovering ? Ink.selection : Ink.surface,
            in: RoundedRectangle(cornerRadius: KitMetric.controlRadius, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: KitMetric.controlRadius, style: .continuous)
            .strokeBorder(isHovering ? Color.accentColor.opacity(0.55) : Ink.divider, lineWidth: 1))
        .onHover { isHovering = $0 }
        .animation(KitMotion.hover, value: isHovering)
        .overlay {
            PromiseDragView(dataProvider: dataProvider, filename: filename)
                .contentShape(Rectangle())
                .accessibilityLabel("Drag to Save")
                .accessibilityHint("Create a PNG file from this screenshot")
        }
        .help("Drag this screenshot to create a PNG file")
    }
}

private struct PromiseDragView: NSViewRepresentable {
    let dataProvider: @MainActor () -> Data?
    let filename: String

    func makeNSView(context: Context) -> PromiseDragNSView {
        let view = PromiseDragNSView()
        view.dataProvider = dataProvider
        view.filename = filename
        return view
    }

    func updateNSView(_ view: PromiseDragNSView, context: Context) {
        view.dataProvider = dataProvider
        view.filename = filename
    }
}

private final class PromiseDragNSView: NSView, NSDraggingSource {
    var dataProvider: (@MainActor () -> Data?)?
    var filename = "Screenshot.png"
    private var promise: ScreenshotFilePromise?

    override var acceptsFirstResponder: Bool { false }
    override var mouseDownCanMoveWindow: Bool { false }
    override func accessibilityLabel() -> String? { "Drag to Save" }
    override func accessibilityHelp() -> String? { "Drag this screenshot to create a PNG file" }

    override func mouseDragged(with event: NSEvent) {
        guard let data = dataProvider?() else { return }
        let promise = ScreenshotFilePromise(data: data, filename: filename)
        self.promise = promise
        let writer = NSFilePromiseProvider(fileType: UTType.png.identifier, delegate: promise)
        let item = NSDraggingItem(pasteboardWriter: writer)
        let image = NSImage(data: data)
        item.setDraggingFrame(bounds, contents: image)
        beginDraggingSession(with: [item], event: event, source: self)
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        .copy
    }
}

private final class ScreenshotFilePromise: NSObject, NSFilePromiseProviderDelegate {
    nonisolated let data: Data
    nonisolated let filename: String

    init(data: Data, filename: String) {
        self.data = data
        self.filename = filename
    }

    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        filename
    }

    nonisolated func filePromiseProvider(
        _ filePromiseProvider: NSFilePromiseProvider,
        writePromiseTo url: URL,
        completionHandler: @escaping (Error?) -> Void
    ) {
        do {
            try data.write(to: url, options: .atomic)
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }

    func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue {
        .main
    }
}
