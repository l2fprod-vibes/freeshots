import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DragToSaveControl: View {
    let dataProvider: @MainActor () -> Data?
    @State private var isHovering = false

    var body: some View {
        ZStack {
            Image(systemName: "arrow.up.doc")
                .foregroundStyle(Ink.text)
                .frame(width: KitMetric.toolSize, height: KitMetric.toolSize)
                .background(
                    isHovering ? Ink.selection : .clear,
                    in: RoundedRectangle(cornerRadius: KitMetric.controlRadius, style: .continuous)
                )
                .onHover { isHovering = $0 }
                .animation(KitMotion.hover, value: isHovering)
            PromiseDragView(dataProvider: dataProvider)
                .accessibilityLabel("Drag to Save")
                .accessibilityHint("Create a PNG file from this screenshot")
        }
        .help("Drag this screenshot to create a PNG file")
    }
}

private struct PromiseDragView: NSViewRepresentable {
    let dataProvider: @MainActor () -> Data?

    func makeNSView(context: Context) -> PromiseDragNSView {
        let view = PromiseDragNSView()
        view.dataProvider = dataProvider
        return view
    }

    func updateNSView(_ view: PromiseDragNSView, context: Context) {
        view.dataProvider = dataProvider
    }
}

private final class PromiseDragNSView: NSView, NSDraggingSource {
    var dataProvider: (@MainActor () -> Data?)?
    private var promise: ScreenshotFilePromise?

    override var acceptsFirstResponder: Bool { false }
    override var mouseDownCanMoveWindow: Bool { false }
    override func accessibilityLabel() -> String? { "Drag to Save" }
    override func accessibilityHelp() -> String? { "Drag this screenshot to create a PNG file" }

    override func mouseDragged(with event: NSEvent) {
        guard let data = dataProvider?() else { return }
        let promise = ScreenshotFilePromise(data: data)
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

    init(data: Data) {
        self.data = data
        self.filename = ScreenshotExport.suggestedFilename
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
