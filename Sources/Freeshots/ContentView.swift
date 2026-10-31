import SwiftUI

struct ContentView: View {
    @Environment(CaptureCoordinator.self) private var coordinator
    @FocusState private var textFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            editorHeader
            Rectangle().fill(Ink.divider).frame(height: 1)

            if let screenshot = coordinator.screenshot {
                HStack(spacing: 0) {
                    editorToolbar
                    Rectangle().fill(Ink.divider).frame(width: 1)
                    MarkupCanvas(image: screenshot)
                        .padding(24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Ink.canvas)
                }
            } else {
                captureState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Ink.canvas)
            }
        }
        .background(WindowChrome())
        .ignoresSafeArea()
        .focusEffectDisabled()
        .onDeleteCommand { coordinator.markup.removeSelected() }
    }

    private var editorHeader: some View {
        HStack(spacing: 12) {
            Text(coordinator.requestedMode?.title ?? "Freeshots")
                .kitType(.labelStrong)
                .foregroundStyle(Ink.text)
                .lineLimit(1)
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

    @ViewBuilder
    private var captureState: some View {
        if let error = coordinator.captureError {
            VStack(spacing: 12) {
                KitIconView(icon: .viewfinder, size: 28)
                    .foregroundStyle(Ink.accentText)
                Text("Capture unavailable")
                    .kitType(.title)
                    .foregroundStyle(Ink.text)
                Text(error)
                    .kitType(.body)
                    .foregroundStyle(Ink.muted)
                    .multilineTextAlignment(.center)
                if coordinator.screenRecordingPermissionMissing {
                    Button("Open Screen Recording Settings") {
                        openScreenRecordingSettings()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(32)
        } else {
            VStack(spacing: 12) {
                KitIconView(icon: .viewfinder, size: 28)
                    .foregroundStyle(Ink.accentText)
                Text("Capturing…")
                    .kitType(.title)
                    .foregroundStyle(Ink.text)
                ProgressView().controlSize(.small)
            }
            .padding(32)
        }
    }

    private var editorToolbar: some View {
        VStack(spacing: 8) {
            ForEach(MarkupTool.allCases) { tool in
                KitToolButton(icon: tool.icon, title: tool.title, shortcut: tool.shortcut,
                              selected: coordinator.markup.activeTool == tool) {
                    coordinator.markup.activeTool = tool
                }
                .keyboardShortcut(KeyEquivalent(tool.shortcut.lowercased().first!), modifiers: [])
                .disabled(textFieldFocused)
            }

            Rectangle().fill(Ink.divider).frame(width: 28, height: 1).padding(.vertical, 4)

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

            DragToSaveControl {
                guard let screenshot = coordinator.screenshot else { return nil }
                return ScreenshotExport.pngData(from: screenshot, annotations: coordinator.markup.annotations)
            }
            .frame(width: 56, height: 60)

            Button { coordinator.copyScreenshot() } label: {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(KitToolButtonStyle())
            .keyboardShortcut("c", modifiers: .command)
            .help("Copy screenshot (⌘C)")
            .accessibilityLabel("Copy screenshot")

            Button { coordinator.saveScreenshot() } label: {
                Image(systemName: "square.and.arrow.down")
            }
            .buttonStyle(.kit(.primary))
            .keyboardShortcut("s", modifiers: .command)
            .help("Save screenshot (⌘S)")
            .accessibilityLabel("Save screenshot")
        }
        .padding(.vertical, 16)
        .frame(width: 64)
        .frame(maxHeight: .infinity)
        .background(Ink.surface)
    }

    private func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
