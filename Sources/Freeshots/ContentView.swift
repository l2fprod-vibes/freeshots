import SwiftUI

struct ContentView: View {
    @Environment(CaptureCoordinator.self) private var coordinator
    @FocusState private var textFieldFocused: Bool
    private static let emptyCanvasImage: NSImage = {
        let size = NSSize(width: 1600, height: 1000)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        image.unlockFocus()
        return image
    }()

    var body: some View {
        VStack(spacing: 0) {
            editorHeader
            Rectangle().fill(Ink.divider).frame(height: 1)

            MarkupCanvas(image: coordinator.screenshot ?? Self.emptyCanvasImage)
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Ink.canvas)
                .overlay(Rectangle().stroke(Ink.divider, lineWidth: 1).padding(24))

            if coordinator.captureError != nil || coordinator.screenshot != nil {
                Rectangle().fill(Ink.divider).frame(height: 1)
                HStack {
                    if coordinator.screenRecordingPermissionMissing {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(Ink.warning)
                        Text("Screen Recording permission required")
                            .kitType(.meta)
                            .foregroundStyle(Ink.muted)
                        Button("Open Settings") { coordinator.openScreenRecordingSettings() }
                            .buttonStyle(KitToolButtonStyle())
                            .help("Open Screen Recording privacy settings")
                    } else if let captureError = coordinator.captureError {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(Ink.warning)
                        Text(captureError)
                            .kitType(.meta)
                            .foregroundStyle(Ink.muted)
                            .lineLimit(1)
                            .help(captureError)
                    }
                    Spacer(minLength: 0)
                    DragToSaveControl {
                        guard let screenshot = coordinator.screenshot else { return nil }
                        return ScreenshotExport.pngData(from: screenshot, annotations: coordinator.markup.annotations)
                    }
                    .frame(width: KitMetric.toolSize, height: KitMetric.toolSize)
                    .padding(.trailing, 16)
                    .opacity(coordinator.screenshot == nil ? 0.4 : 1)
                }
                .frame(height: 40)
                .background(Ink.surface)
            }

        }
        .background(WindowChrome())
        .ignoresSafeArea()
        .focusEffectDisabled()
        .onDeleteCommand { coordinator.markup.removeSelected() }
    }

    private var editorHeader: some View {
        HStack(spacing: 8) {
            Button { coordinator.copyScreenshot() } label: {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(KitToolButtonStyle())
            .keyboardShortcut("c", modifiers: .command)
            .help("Copy screenshot (⌘C)")
            .accessibilityLabel("Copy screenshot")
            .disabled(coordinator.screenshot == nil)

            Button { coordinator.saveScreenshot() } label: {
                Image(systemName: "square.and.arrow.down")
            }
            .buttonStyle(KitToolButtonStyle())
            .keyboardShortcut("s", modifiers: .command)
            .help("Save screenshot (⌘S)")
            .accessibilityLabel("Save screenshot")
            .disabled(coordinator.screenshot == nil)

            Rectangle().fill(Ink.divider).frame(width: 1, height: 24).padding(.horizontal, 8)

            ForEach(MarkupTool.allCases) { tool in
                KitToolButton(icon: tool.icon, title: tool.title, shortcut: tool.shortcut,
                              selected: coordinator.markup.activeTool == tool) {
                    coordinator.markup.activeTool = tool
                }
                .keyboardShortcut(KeyEquivalent(tool.shortcut.lowercased().first!), modifiers: [])
                .disabled(textFieldFocused)

            }

            Rectangle().fill(Ink.divider).frame(width: 1, height: 24).padding(.horizontal, 8)

            Button { coordinator.markup.undo() } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .buttonStyle(KitToolButtonStyle())
            .disabled(!coordinator.markup.canUndo)
            .keyboardShortcut("z", modifiers: .command)
            .help("Undo (⌘Z)")

            Button { coordinator.markup.redo() } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .buttonStyle(KitToolButtonStyle())
            .disabled(!coordinator.markup.canRedo)
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .help("Redo (⇧⌘Z)")

            if coordinator.markup.selectedMark != nil {
                Button { coordinator.markup.removeSelected() } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(KitToolButtonStyle())
                .help("Remove selected mark (Delete)")
            }

            Spacer(minLength: 8)
            if let mark = coordinator.markup.selectedMark, mark.tool == .text {
                TextField("Text", text: Binding(
                    get: { coordinator.markup.selectedMark?.text ?? "" },
                    set: { coordinator.markup.updateSelectedText($0) }
                ), onEditingChanged: { editing in
                    if editing { coordinator.markup.selectedTextChanged() }
                })
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)
                .focused($textFieldFocused)
                .accessibilityLabel("Edit selected text mark")
            }
            if let message = coordinator.statusMessage {
                Text(message)
                    .kitType(.meta)
                    .foregroundStyle(Ink.muted)
                    .lineLimit(1)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .padding(.leading, 84)
        .padding(.trailing, 20)
        .frame(height: 48)
        .background(Ink.surface)
    }

}
