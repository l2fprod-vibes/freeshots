import AppKit
import Observation
import SwiftUI
import FreeshotsCore
import FreeshotsRendering

extension MarkupTool {
    var icon: KitIcon {
        switch self {
        case .select: .select
        case .arrow: .arrow
        case .shape: .shape
        case .text: .text
        case .pen: .pen
        case .redact: .redact
        case .blur: .redact
        }
    }
}

@MainActor
@Observable
final class MarkupDocument {
    var annotations: [ScreenshotMark] = []
    var cropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    var cropDraft: CGRect?
    var isCropping = false
    var activeTool: MarkupTool = .select
    var activeColorHex = "E53935"
    var activeArrowStyle: ArrowStyle = .solid
    var selectedID: UUID?
    @ObservationIgnored private var undoStack: [MarkupHistoryState] = []
    @ObservationIgnored private var redoStack: [MarkupHistoryState] = []

    var selectedMark: ScreenshotMark? { annotations.first { $0.id == selectedID } }
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func reset() {
        annotations.removeAll()
        cropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        cropDraft = nil
        isCropping = false
        selectedID = nil
        activeTool = .select
        undoStack.removeAll()
        redoStack.removeAll()
    }

    func beginUndoGroup() {
        undoStack.append(MarkupHistoryState(annotations: annotations, cropRect: cropRect))
        redoStack.removeAll()
    }

    func beginCrop() { isCropping = true; cropDraft = CGRect(x: 0, y: 0, width: 1, height: 1) }

    func updateCropDraft(_ rect: CGRect) {
        cropDraft = rect.standardized.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
    }

    func applyCrop() {
        guard let cropDraft, cropDraft.width > 0.02, cropDraft.height > 0.02 else { return }
        beginUndoGroup()
        cropRect = cropDraft
        self.cropDraft = nil
        isCropping = false
    }

    func cancelCrop() { cropDraft = nil; isCropping = false }

    func add(_ annotation: ScreenshotMark) {
        beginUndoGroup()
        annotations.append(annotation)
        selectedID = annotation.id
    }

    func replace(_ annotation: ScreenshotMark) {
        guard let index = annotations.firstIndex(where: { $0.id == annotation.id }) else { return }
        annotations[index] = annotation
    }

    func updateSelectedText(_ text: String) {
        guard let index = annotations.firstIndex(where: { $0.id == selectedID }) else { return }
        annotations[index].text = text
    }

    func selectedTextChanged() { beginUndoGroup() }

    func removeSelected() {
        guard let selectedID, annotations.contains(where: { $0.id == selectedID }) else { return }
        beginUndoGroup()
        annotations.removeAll { $0.id == selectedID }
        self.selectedID = nil
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(MarkupHistoryState(annotations: annotations, cropRect: cropRect))
        annotations = previous.annotations
        cropRect = previous.cropRect
        selectedID = nil
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(MarkupHistoryState(annotations: annotations, cropRect: cropRect))
        annotations = next.annotations
        cropRect = next.cropRect
        selectedID = nil
    }
}

private struct MarkupHistoryState {
    let annotations: [ScreenshotMark]
    let cropRect: CGRect
}

struct MarkupCanvas: View {
    let image: NSImage
    let appearance: ScreenshotAppearance
    @Environment(MarkupDocument.self) private var markup
    @State private var draft: ScreenshotMark?
    @State private var movingID: UUID?
    @State private var moveOrigin: CGPoint = .zero
    @State private var originalMark: ScreenshotMark?

    init(image: NSImage, appearance: ScreenshotAppearance) {
        self.image = image
        self.appearance = appearance
    }

    var body: some View {
        GeometryReader { geometry in
            let visibleCrop = markup.isCropping ? CGRect(x: 0, y: 0, width: 1, height: 1) : markup.cropRect
            let visibleSize = ScreenshotArtworkView.croppedSize(image.size, cropRect: visibleCrop)
            let imageRect = ScreenshotArtworkView.imageRect(imageSize: visibleSize, in: geometry.size, appearance: appearance)
            ZStack {
            ScreenshotArtworkView(image: image, appearance: appearance, annotations: markup.annotations,
                                  cropRect: visibleCrop,
                                  selectedID: markup.selectedID, draft: draft, selectionColor: Ink.accentText)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .allowsHitTesting(!markup.isCropping)
            .gesture(DragGesture(minimumDistance: markup.activeTool == .select || markup.activeTool == .text ? 0 : 2)
                .onChanged { value in
                    handleChange(value, in: imageRect)
                }
                .onEnded { value in
                    handleEnd(value, in: imageRect)
                })
                if markup.isCropping, let cropDraft = markup.cropDraft {
                    CropSelectionOverlay(imageRect: imageRect, canvasSize: geometry.size, selection: cropDraft) {
                        markup.updateCropDraft($0)
                    }
                }
            }
        }
        .accessibilityLabel("Screenshot markup canvas")
        .onChange(of: markup.activeTool) { _, _ in
            draft = nil
            movingID = nil
            originalMark = nil
            markup.selectedID = nil
        }
    }

    private func normalized(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        let localX = min(1, max(0, (point.x - rect.minX) / rect.width))
        let localY = min(1, max(0, (point.y - rect.minY) / rect.height))
        return CGPoint(x: markup.cropRect.minX + localX * markup.cropRect.width,
                       y: markup.cropRect.minY + localY * markup.cropRect.height)
    }

    private func handleChange(_ value: DragGesture.Value, in rect: CGRect) {
        let point = normalized(value.location, in: rect)
        if markup.activeTool == .select {
            if movingID == nil {
                movingID = hitTest(point)
                markup.selectedID = movingID
                moveOrigin = point
                originalMark = markup.selectedMark
                if movingID != nil { markup.beginUndoGroup() }
            }
            if let originalMark {
                let delta = CGPoint(x: point.x - moveOrigin.x, y: point.y - moveOrigin.y)
                markup.replace(originalMark.offsetBy(delta))
            }
            return
        }

        if draft == nil {
            draft = ScreenshotMark(tool: markup.activeTool, start: point, end: point,
                                   points: markup.activeTool == .pen ? [point] : [], colorHex: markup.activeColorHex,
                                   arrowStyle: markup.activeArrowStyle)
        } else {
            draft?.end = point
            if markup.activeTool == .pen { draft?.points.append(point) }
        }
    }

    private func handleEnd(_ value: DragGesture.Value, in rect: CGRect) {
        if markup.activeTool == .select {
            if movingID == nil { markup.selectedID = hitTest(normalized(value.location, in: rect)) }
            movingID = nil
            originalMark = nil
            return
        }
        guard var mark = draft else { return }
        mark.end = normalized(value.location, in: rect)
        if mark.tool == .text {
            mark.text = "Text"
            markup.add(mark)
        } else if mark.tool == .pen || mark.normalizedBounds.width > 0.004 || mark.normalizedBounds.height > 0.004 {
            markup.add(mark)
        }
        draft = nil
    }

    private func hitTest(_ point: CGPoint) -> UUID? {
        for mark in markup.annotations.reversed() {
            if mark.normalizedBounds.insetBy(dx: -0.025, dy: -0.025).contains(point) { return mark.id }
        }
        return nil
    }

}

extension NSColor {
    convenience init?(hex: String) {
        guard let value = UInt32(hex, radix: 16) else { return nil }
        self.init(calibratedRed: CGFloat((value >> 16) & 255) / 255,
                  green: CGFloat((value >> 8) & 255) / 255,
                  blue: CGFloat(value & 255) / 255, alpha: 1)
    }
    var hexString: String {
        let color = usingColorSpace(.deviceRGB) ?? .systemRed
        return String(format: "%02X%02X%02X", Int(color.redComponent * 255), Int(color.greenComponent * 255), Int(color.blueComponent * 255))
    }
}


struct BackdropPreview: View {
    let preset: BackdropPreset
    var body: some View {
        ZStack {
            if preset.colors.isEmpty {
                Color.clear
            } else {
                LinearGradient(colors: preset.colors.compactMap { NSColor(hex: $0).map { Color(nsColor: $0) } },
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            if preset.texture {
                Canvas { context, size in
                    let step: CGFloat = preset == .blueprint ? 32 : preset == .graphiteGrid ? 24 : preset == .roseDots ? 12 : preset == .sand ? 9 : 7
                    if preset.usesGridTexture {
                        let opacity = preset == .blueprint ? 0.16 : 0.10
                        for x in stride(from: 0, through: size.width, by: step) {
                            var path = Path(); path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height))
                            context.stroke(path, with: .color(.white.opacity(opacity)), lineWidth: 1)
                        }
                        for y in stride(from: 0, through: size.height, by: step) {
                            var path = Path(); path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(path, with: .color(.white.opacity(opacity)), lineWidth: 1)
                        }
                    } else {
                        let dotColor: Color = preset == .sand ? .black.opacity(0.12) : .white.opacity(0.12)
                        for y in stride(from: 0, through: size.height, by: step) {
                            let offset = preset.usesDiagonalDotTexture ? (Int(y / step).isMultiple(of: 2) ? 0 : step / 2) : 0
                            for x in stride(from: offset, through: size.width, by: step) {
                                let diameter: CGFloat = preset.usesDiagonalDotTexture ? 2 : 1
                                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter)), with: .color(dotColor))
                            }
                        }
                    }
                }
            }
        }
    }
}
