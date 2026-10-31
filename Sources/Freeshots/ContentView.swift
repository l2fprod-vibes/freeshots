import SwiftUI
import FreeshotsCore

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

            HStack(spacing: 0) {
                MarkupCanvas(image: coordinator.screenshot ?? Self.emptyCanvasImage, appearance: coordinator.appearance)
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Ink.canvas)
                    .overlay(Rectangle().stroke(Ink.divider, lineWidth: 1).padding(24))

                Rectangle().fill(Ink.divider).frame(width: 1)
                EditorInspector(coordinator: coordinator, textFieldFocused: $textFieldFocused)
                    .frame(width: 304)
                    .background(.regularMaterial)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if coordinator.captureError != nil {
                Rectangle().fill(Ink.divider).frame(height: 1)
                HStack {
                    if coordinator.screenRecordingPermissionMissing {
                        Image(systemName: "exclamationmark.triangle").foregroundStyle(Ink.warning)
                        Text("Screen Recording permission required").kitType(.meta).foregroundStyle(Ink.muted)
                        Button("Open Settings") { coordinator.openScreenRecordingSettings() }
                            .buttonStyle(KitToolButtonStyle()).help("Open Screen Recording privacy settings")
                    } else if let captureError = coordinator.captureError {
                        Image(systemName: "exclamationmark.triangle").foregroundStyle(Ink.warning)
                        Text(captureError).kitType(.meta).foregroundStyle(Ink.muted).lineLimit(1).help(captureError)
                    }
                    Spacer(minLength: 0)
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
            Spacer(minLength: 8)
            if let message = coordinator.statusMessage {
                Text(message).kitType(.meta).foregroundStyle(Ink.muted).lineLimit(1)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .padding(.leading, 84)
        .padding(.trailing, 20)
        .frame(height: 48)
        .background(Ink.surface)
    }
}

private struct EditorInspector: View {
    @Bindable var coordinator: CaptureCoordinator
    @FocusState.Binding var textFieldFocused: Bool
    private let toolColumns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
    private let backdropColumns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 8) {
                    Button { coordinator.copyScreenshot() } label: { Image(systemName: "doc.on.doc") }
                    .buttonStyle(KitToolButtonStyle())
                    .keyboardShortcut("c", modifiers: .command)
                    .help("Copy screenshot (⌘C)")
                    .accessibilityLabel("Copy screenshot")
                    .disabled(coordinator.screenshot == nil)

                    Button { coordinator.saveScreenshot() } label: { Image(systemName: "square.and.arrow.down") }
                    .buttonStyle(KitToolButtonStyle())
                    .keyboardShortcut("s", modifiers: .command)
                    .help("Save screenshot (⌘S)")
                    .accessibilityLabel("Save screenshot")
                    .disabled(coordinator.screenshot == nil)

                    Button { coordinator.markup.undo() } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .buttonStyle(KitToolButtonStyle())
                    .disabled(!coordinator.markup.canUndo)
                    .keyboardShortcut("z", modifiers: .command)
                    .help("Undo (⌘Z)")
                    .accessibilityLabel("Undo")

                    Button { coordinator.markup.redo() } label: {
                        Image(systemName: "arrow.uturn.forward")
                    }
                    .buttonStyle(KitToolButtonStyle())
                    .disabled(!coordinator.markup.canRedo)
                    .keyboardShortcut("z", modifiers: [.command, .shift])
                    .help("Redo (⇧⌘Z)")
                    .accessibilityLabel("Redo")

                    DragToSaveControl {
                        guard let screenshot = coordinator.screenshot else { return nil }
                        return ScreenshotExport.pngData(from: screenshot, annotations: coordinator.markup.annotations, appearance: coordinator.appearance)
                    }
                    .frame(width: KitMetric.toolSize, height: KitMetric.toolSize)
                    .opacity(coordinator.screenshot == nil ? 0.4 : 1)
                }
                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle("Markup", symbol: "pencil.tip.crop.circle")
                    LazyVGrid(columns: toolColumns, spacing: 8) {
                        ForEach(MarkupTool.allCases) { tool in
                            Button {
                                coordinator.markup.activeTool = tool
                            } label: {
                                Label(tool.title, systemImage: tool.symbol)
                                    .font(.system(size: 12, weight: coordinator.markup.activeTool == tool ? .semibold : .regular))
                                    .frame(maxWidth: .infinity, minHeight: 32)
                                    .background(coordinator.markup.activeTool == tool ? Ink.selection : .clear,
                                                in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(coordinator.markup.activeTool == tool ? Ink.accentText : Ink.text)
                            .help("Choose \(tool.title) (\(tool.shortcut))")
                            .accessibilityLabel(tool.title)
                            .keyboardShortcut(KeyEquivalent(tool.shortcut.lowercased().first!), modifiers: [])
                            .disabled(textFieldFocused)
                        }
                    }
                    HStack {
                        Text("Color").kitType(.label)
                        ColorMenu(coordinator: coordinator)
                        Spacer()
                        if coordinator.markup.selectedMark != nil {
                            Button { coordinator.markup.removeSelected() } label: { Image(systemName: "trash") }
                                .buttonStyle(KitToolButtonStyle())
                                .help("Remove selected mark (Delete)")
                                .accessibilityLabel("Remove selected mark")
                        }
                    }
                    if let mark = coordinator.markup.selectedMark, mark.tool == .text {
                        TextField("Text", text: Binding(
                            get: { coordinator.markup.selectedMark?.text ?? "" },
                            set: { coordinator.markup.updateSelectedText($0) }
                        ), onEditingChanged: { editing in
                            if editing { coordinator.markup.selectedTextChanged() }
                        })
                        .textFieldStyle(.roundedBorder)
                        .focused($textFieldFocused)
                        .accessibilityLabel("Edit selected text mark")
                    }
                }

                Rectangle().fill(Ink.divider).frame(height: 1)

                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("Backdrop", symbol: "rectangle.inset.filled")
                    LazyVGrid(columns: backdropColumns, spacing: 8) {
                        ForEach(BackdropPreset.allCases) { preset in
                            Button { coordinator.appearance.backdrop = preset } label: {
                                VStack(spacing: 4) {
                                    BackdropPreview(preset: preset)
                                        .frame(height: 34)
                                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(
                                            coordinator.appearance.backdrop == preset ? Color.accentColor : Ink.divider,
                                            lineWidth: coordinator.appearance.backdrop == preset ? 2 : 1
                                        ))
                                    Text(preset.title).font(.system(size: 10)).lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .help("Use \(preset.title) background")
                            .accessibilityLabel("\(preset.title) background")
                        }
                    }
                    appearanceSlider("Padding", value: $coordinator.appearance.padding, range: 0...240, step: 8)
                    appearanceSlider("Corners", value: $coordinator.appearance.cornerRadius, range: 0...64, step: 2)
                    Toggle("Shadow", isOn: $coordinator.appearance.shadowEnabled)
                    if coordinator.appearance.shadowEnabled {
                        appearanceSlider("Blur", value: $coordinator.appearance.shadowBlur, range: 0...64, step: 2)
                        appearanceSlider("Opacity", value: $coordinator.appearance.shadowOpacity, range: 0...0.8, step: 0.04, suffix: "%", multiplier: 100)
                    }
                    Picker("Device Frame", selection: $coordinator.appearance.frame) {
                        ForEach(DeviceFrame.allCases) { frame in Text(frame.title).tag(frame) }
                    }
                    .pickerStyle(.segmented)
                    Button("Reset Backdrop") { coordinator.appearance = .defaults }
                        .buttonStyle(.borderless)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(16)
        }
        .accessibilityLabel("Screenshot tools and appearance")
    }

    private func sectionTitle(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Ink.text)
    }

    private func appearanceSlider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double,
                                 suffix: String = " px", multiplier: Double = 1) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title).kitType(.label)
                Spacer()
                Text("\(Int(value.wrappedValue * multiplier))\(suffix)")
                    .kitType(.meta).monospacedDigit().foregroundStyle(Ink.muted)
            }
            Slider(value: value, in: range, step: step)
                .accessibilityLabel(title)
        }
    }
}

private struct ColorMenu: View {
    @Bindable var coordinator: CaptureCoordinator
    private let swatches = ["E53935", "FF8A00", "F4C20D", "2EAF62", "1688E8", "7451D3", "111111", "FFFFFF"]
    @State private var customColor = Color.red
    @State private var isPresented = false

    var body: some View {
        Button {
            customColor = Color(nsColor: NSColor(hex: coordinator.markup.activeColorHex) ?? .systemRed)
            isPresented = true
        } label: {
            Circle()
                .fill(Color(nsColor: NSColor(hex: coordinator.markup.activeColorHex) ?? .systemRed))
                .frame(width: 18, height: 18)
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.28), lineWidth: 1))
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(KitToolButtonStyle())
        .help("Choose markup color")
        .accessibilityLabel("Markup Color")
        .popover(isPresented: $isPresented, arrowEdge: .trailing) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Markup Color").font(.headline)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(26), spacing: 8), count: 4), spacing: 8) {
                    ForEach(swatches, id: \.self) { hex in
                        Button {
                            coordinator.markup.activeColorHex = hex
                            isPresented = false
                        } label: {
                            Circle().fill(Color(nsColor: NSColor(hex: hex) ?? .systemRed))
                                .frame(width: 22, height: 22)
                                .overlay(Circle().strokeBorder(Color.primary.opacity(hex == "FFFFFF" ? 0.35 : 0.12), lineWidth: 1))
                                .overlay {
                                    if coordinator.markup.activeColorHex == hex {
                                        Image(systemName: "checkmark").font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(hex == "FFFFFF" ? .black : .white)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .help("Set markup color to #\(hex)")
                    }
                }
                ColorPicker("Custom Color", selection: $customColor, supportsOpacity: false)
                    .onChange(of: customColor) { _, value in
                        coordinator.markup.activeColorHex = (NSColor(cgColor: value.cgColor ?? NSColor.systemRed.cgColor) ?? .systemRed).hexString
                    }
            }
            .padding(16)
            .frame(width: 180)
        }
    }
}
