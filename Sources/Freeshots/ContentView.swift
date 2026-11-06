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
            EditorToolbar(coordinator: coordinator, textFieldFocused: $textFieldFocused)
            Rectangle().fill(Ink.divider).frame(height: 1)
            MarkupCanvas(image: coordinator.screenshot ?? Self.emptyCanvasImage, appearance: coordinator.appearance)
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Ink.canvas)
            if let statusMessage = coordinator.statusMessage {
                HStack(spacing: 8) {
                    Image(systemName: statusMessage.hasPrefix("Unable") ? "exclamationmark.triangle" : "checkmark.circle")
                        .foregroundStyle(statusMessage.hasPrefix("Unable") ? Ink.warning : Ink.muted)
                    Text(statusMessage).kitType(.meta).foregroundStyle(Ink.muted).lineLimit(1).help(statusMessage)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Ink.surface)
                .accessibilityAddTraits(.updatesFrequently)
            }
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
        .onDeleteCommand { coordinator.markup.removeSelected() }
    }
}

private struct EditorToolbar: View {
    @Bindable var coordinator: CaptureCoordinator
    @FocusState.Binding var textFieldFocused: Bool
    @State private var backgroundPresented = false
    @State private var aspectRatioPresented = false
    @State private var fineTunePresented = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(MarkupTool.allCases) { tool in
                if tool == .arrow {
                    Menu {
                        ForEach(ArrowStyle.allCases) { style in
                            Button {
                                coordinator.markup.activeArrowStyle = style
                                coordinator.markup.activeTool = .arrow
                            } label: {
                                if coordinator.markup.activeArrowStyle == style {
                                    Label(style.title, systemImage: "checkmark")
                                } else {
                                    Text(style.title)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: tool.symbol)
                            .font(.system(size: 15, weight: coordinator.markup.activeTool == tool ? .semibold : .regular))
                    }
                    .menuStyle(.borderlessButton)
                    .buttonStyle(KitToolButtonStyle(selected: coordinator.markup.activeTool == tool))
                    .help("Choose Arrow Style (A)")
                    .accessibilityLabel("Arrow")
                    .accessibilityValue(coordinator.markup.activeArrowStyle.title)
                    .accessibilityAddTraits(coordinator.markup.activeTool == tool ? .isSelected : [])
                    .disabled(textFieldFocused)
                } else {
                    Button { coordinator.markup.activeTool = tool } label: {
                        Image(systemName: tool.symbol)
                            .font(.system(size: 15, weight: coordinator.markup.activeTool == tool ? .semibold : .regular))
                    }
                    .buttonStyle(KitToolButtonStyle(selected: coordinator.markup.activeTool == tool))
                    .help("Choose \(tool.title) (\(tool.shortcut))")
                    .accessibilityLabel(tool.title)
                    .accessibilityAddTraits(coordinator.markup.activeTool == tool ? .isSelected : [])
                    .keyboardShortcut(KeyEquivalent(tool.shortcut.lowercased().first!), modifiers: [])
                    .disabled(textFieldFocused)
                }
            }

            ColorMenu(coordinator: coordinator)

            if let mark = coordinator.markup.selectedMark, mark.tool == .text {
                TextField("Text", text: Binding(
                    get: { coordinator.markup.selectedMark?.text ?? "" },
                    set: { coordinator.markup.updateSelectedText($0) }
                ), onEditingChanged: { editing in
                    if editing { coordinator.markup.selectedTextChanged() }
                })
                .textFieldStyle(.roundedBorder)
                .frame(width: 160)
                .focused($textFieldFocused)
                .accessibilityLabel("Edit selected text mark")
            }
            if coordinator.markup.selectedMark != nil {
                toolButton("trash", title: "Remove selected mark", help: "Remove selected mark (Delete)") {
                    coordinator.markup.removeSelected()
                }
            }

            toolbarDivider

            toolButton("arrow.uturn.backward", title: "Undo", help: "Undo (⌘Z)") { coordinator.markup.undo() }
                .disabled(!coordinator.markup.canUndo)
                .keyboardShortcut("z", modifiers: .command)
            toolButton("arrow.uturn.forward", title: "Redo", help: "Redo (⇧⌘Z)") { coordinator.markup.redo() }
                .disabled(!coordinator.markup.canRedo)
                .keyboardShortcut("z", modifiers: [.command, .shift])

            toolbarDivider

            Button { backgroundPresented = true } label: { Image(systemName: "paintpalette") }
                .buttonStyle(KitToolButtonStyle(selected: backgroundPresented))
                .help("Preview and choose a background")
                .accessibilityLabel("Background")
                .accessibilityValue(coordinator.appearance.backdrop.title)
                .popover(isPresented: $backgroundPresented, arrowEdge: .bottom) {
                    BackgroundPopover(coordinator: coordinator)
                }
            Button { aspectRatioPresented = true } label: { Image(systemName: "aspectratio") }
                .buttonStyle(KitToolButtonStyle(selected: aspectRatioPresented))
                .help("Preview and choose an aspect ratio")
                .accessibilityLabel("Aspect Ratio")
                .accessibilityValue(coordinator.appearance.aspectRatio.title)
                .popover(isPresented: $aspectRatioPresented, arrowEdge: .bottom) {
                    AspectRatioPopover(coordinator: coordinator,
                                      imageSize: coordinator.screenshot?.size ?? CGSize(width: 16, height: 9))
                }
            appearanceMenu("Device Frame", symbol: "macwindow", selection: coordinator.appearance.frame.title) {
                ForEach(DeviceFrame.allCases) { frame in
                    Button(frame.title) { coordinator.appearance.frame = frame }
                }
            }
            Button { fineTunePresented = true } label: { Image(systemName: "slider.horizontal.3") }
                .buttonStyle(KitToolButtonStyle())
                .help("Adjust fine tune settings")
                .accessibilityLabel("Fine Tune")
                .popover(isPresented: $fineTunePresented, arrowEdge: .bottom) {
                    FineTunePopover(coordinator: coordinator)
                }
            toolButton("arrow.counterclockwise", title: "Reset Appearance", help: "Reset screenshot appearance") {
                coordinator.appearance = ScreenshotAppearance(
                    backdrop: .transparent,
                    padding: 0,
                    cornerRadius: 0,
                    backdropCornerRadius: 0,
                    shadowEnabled: false,
                    shadowBlur: 0,
                    shadowOpacity: 0,
                    frame: .none,
                    aspectRatio: .original
                )
            }

            Spacer(minLength: 8)

            toolButton("doc.on.doc", title: "Copy screenshot", help: "Copy screenshot (⌘C)") {
                coordinator.copyScreenshot()
            }
            .keyboardShortcut("c", modifiers: .command)
            .disabled(coordinator.screenshot == nil)

            toolButton("square.and.arrow.down", title: "Save screenshot", help: "Save screenshot (⌘S)") {
                coordinator.saveScreenshot()
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(coordinator.screenshot == nil)

            DragToSaveControl(dataProvider: {
                guard let screenshot = coordinator.screenshot else { return nil }
                return ScreenshotExport.pngData(from: screenshot, annotations: coordinator.markup.annotations, appearance: coordinator.appearance)
            }, filename: ScreenshotExport.filename(for: coordinator.screenshotName))
            .opacity(coordinator.screenshot == nil ? 0.4 : 1)
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(.regularMaterial)
        .accessibilityLabel("Screenshot editing tools")
    }

    private var toolbarDivider: some View {
        Rectangle().fill(Ink.divider).frame(width: 1, height: 24).padding(.horizontal, 4)
    }

    private func appearanceMenu<Content: View>(_ title: String, symbol: String, selection: String,
                                               @ViewBuilder content: () -> Content) -> some View {
        Menu(content: content) {
            Image(systemName: symbol)
        }
        .menuIndicator(.hidden)
        .menuStyle(.borderlessButton)
        .frame(width: KitMetric.toolSize, height: KitMetric.toolSize)
        .help("Choose \(title.lowercased()) (\(selection))")
        .accessibilityLabel(title)
        .accessibilityValue(selection)
    }

    private func toolButton(_ symbol: String, title: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol) }
            .buttonStyle(KitToolButtonStyle())
            .help(help)
            .accessibilityLabel(title)
    }
}

private struct BackgroundPopover: View {
    @Bindable var coordinator: CaptureCoordinator
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Background").font(.headline)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(BackdropPreset.allCases) { preset in
                    Button { coordinator.appearance.backdrop = preset } label: {
                        VStack(spacing: 5) {
                            BackdropPreview(preset: preset)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(.white.opacity(0.88))
                                        .frame(width: 28, height: 18)
                                        .shadow(color: .black.opacity(0.16), radius: 2, y: 1)
                                }
                                .frame(height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(coordinator.appearance.backdrop == preset ? Color.accentColor : Ink.divider,
                                                  lineWidth: coordinator.appearance.backdrop == preset ? 2 : 1))
                            Text(preset.title).font(.system(size: 11)).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Use \(preset.title) background")
                    .accessibilityLabel("\(preset.title) background")
                    .accessibilityAddTraits(coordinator.appearance.backdrop == preset ? .isSelected : [])
                }
            }
        }
        .padding(16)
        .frame(width: 260)
        .accessibilityLabel("Background choices")
    }
}

private struct AspectRatioPopover: View {
    @Bindable var coordinator: CaptureCoordinator
    let imageSize: CGSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aspect Ratio").font(.headline)
            HStack(alignment: .top, spacing: 8) {
                ForEach(ScreenshotAspectRatio.allCases) { ratio in
                    Button { coordinator.appearance.aspectRatio = ratio } label: {
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(coordinator.appearance.aspectRatio == ratio ? Color.accentColor : Ink.muted.opacity(0.45))
                                .frame(width: previewSize(for: ratio).width, height: previewSize(for: ratio).height)
                                .frame(width: 48, height: 40)
                                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(coordinator.appearance.aspectRatio == ratio ? Color.accentColor : Ink.divider,
                                                  lineWidth: coordinator.appearance.aspectRatio == ratio ? 2 : 1))
                            Text(ratio.title).font(.system(size: 11)).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Use \(ratio.title) aspect ratio")
                    .accessibilityLabel("\(ratio.title) aspect ratio")
                    .accessibilityAddTraits(coordinator.appearance.aspectRatio == ratio ? .isSelected : [])
                }
            }
        }
        .padding(16)
        .frame(width: 280)
        .accessibilityLabel("Aspect ratio choices")
    }

    private func previewSize(for ratio: ScreenshotAspectRatio) -> CGSize {
        let sourceRatio = imageSize.height > 0 ? imageSize.width / imageSize.height : 16.0 / 9.0
        let landscape = sourceRatio >= 1
        let value: CGFloat
        switch ratio {
        case .original: value = sourceRatio
        case .square: value = 1
        case .fourByThree: value = landscape ? 4.0 / 3.0 : 3.0 / 4.0
        case .sixteenByNine: value = landscape ? 16.0 / 9.0 : 9.0 / 16.0
        }
        let width = min(38, 28 * value)
        return CGSize(width: width, height: 28)
    }
}

private struct FineTunePopover: View {
    @Bindable var coordinator: CaptureCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Fine Tune").font(.headline)
            appearanceSlider("Padding", value: $coordinator.appearance.padding, range: 0...240, step: 8)
            appearanceSlider("Screenshot Corners", value: $coordinator.appearance.cornerRadius, range: 0...64, step: 2)
            appearanceSlider("Picture Corners", value: $coordinator.appearance.backdropCornerRadius, range: 0...64, step: 2)
            Toggle("Shadow", isOn: $coordinator.appearance.shadowEnabled)
            appearanceSlider("Shadow Blur", value: $coordinator.appearance.shadowBlur, range: 0...64, step: 2)
                .disabled(!coordinator.appearance.shadowEnabled)
            appearanceSlider("Shadow Opacity", value: $coordinator.appearance.shadowOpacity, range: 0...0.8, step: 0.04, suffix: "%", multiplier: 100)
                .disabled(!coordinator.appearance.shadowEnabled)
        }
        .padding(16)
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel("Fine tune screenshot appearance")
    }

    private func appearanceSlider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double,
                                  suffix: String = " px", multiplier: Double = 1) -> some View {
        VStack(alignment: .leading, spacing: 4) {
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
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
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
            .frame(width: 196)
        }
    }
}
