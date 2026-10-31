import AppKit
import Observation
import SwiftUI
import FreeshotsCore

enum MarkupTool: String, CaseIterable, Identifiable {
    case select, arrow, shape, text, pen, redact

    var id: Self { self }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .select: "cursorarrow"
        case .arrow: "arrow.up.right"
        case .shape: "rectangle"
        case .text: "textformat"
        case .pen: "pencil.tip"
        case .redact: "rectangle.fill"
        }
    }
    var shortcut: String {
        switch self {
        case .select: "V"
        case .arrow: "A"
        case .shape: "R"
        case .text: "T"
        case .pen: "P"
        case .redact: "G"
        }
    }

    var icon: KitIcon {
        switch self {
        case .select: .select
        case .arrow: .arrow
        case .shape: .shape
        case .text: .text
        case .pen: .pen
        case .redact: .redact
        }
    }
}

struct ScreenshotMark: Identifiable, Equatable {
    var id = UUID()
    var tool: MarkupTool
    var start: CGPoint
    var end: CGPoint
    var points: [CGPoint] = []
    var text = ""
    var colorHex = "E53935"

    var normalizedBounds: CGRect {
        if tool == .pen, !points.isEmpty {
            let xs = points.map(\.x), ys = points.map(\.y)
            return CGRect(x: xs.min() ?? 0, y: ys.min() ?? 0,
                          width: (xs.max() ?? 0) - (xs.min() ?? 0),
                          height: (ys.max() ?? 0) - (ys.min() ?? 0))
        }
        return CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
                      width: abs(end.x - start.x), height: abs(end.y - start.y))
    }

    func offsetBy(_ delta: CGPoint) -> ScreenshotMark {
        var copy = self
        copy.start.x += delta.x; copy.start.y += delta.y
        copy.end.x += delta.x; copy.end.y += delta.y
        copy.points = points.map { CGPoint(x: $0.x + delta.x, y: $0.y + delta.y) }
        return copy
    }
}

@MainActor
@Observable
final class MarkupDocument {
    var annotations: [ScreenshotMark] = []
    var activeTool: MarkupTool = .select
    var activeColorHex = "E53935"
    var selectedID: UUID?
    @ObservationIgnored private var undoStack: [[ScreenshotMark]] = []
    @ObservationIgnored private var redoStack: [[ScreenshotMark]] = []

    var selectedMark: ScreenshotMark? { annotations.first { $0.id == selectedID } }
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func reset() {
        annotations.removeAll()
        selectedID = nil
        activeTool = .select
        undoStack.removeAll()
        redoStack.removeAll()
    }

    func beginUndoGroup() {
        undoStack.append(annotations)
        redoStack.removeAll()
    }

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
        redoStack.append(annotations)
        annotations = previous
        selectedID = nil
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(annotations)
        annotations = next
        selectedID = nil
    }
}

struct MarkupCanvas: View {
    let image: NSImage
    let appearance: ScreenshotAppearance
    @Environment(MarkupDocument.self) private var markup
    @State private var draft: ScreenshotMark?
    @State private var movingID: UUID?
    @State private var moveOrigin: CGPoint = .zero
    @State private var originalMark: ScreenshotMark?

    var body: some View {
        GeometryReader { geometry in
            let layout = fittedRects(image.size, in: geometry.size)
            let imageRect = layout.image
            ZStack(alignment: .topLeading) {
                BackdropPreview(preset: appearance.backdrop)
                    .frame(width: layout.backdrop.width, height: layout.backdrop.height)
                    .clipShape(RoundedRectangle(cornerRadius: appearance.cornerRadius * layout.scale, style: .continuous))
                    .position(x: layout.backdrop.midX, y: layout.backdrop.midY)
                if appearance.frame != .none {
                    RoundedRectangle(cornerRadius: appearance.frame == .phone ? 48 * layout.scale : 18 * layout.scale)
                        .fill(Color(white: 0.08))
                        .frame(width: layout.frame.width, height: layout.frame.height)
                        .position(x: layout.frame.midX, y: layout.frame.midY)
                }
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: imageRect.width, height: imageRect.height)
                    .clipShape(RoundedRectangle(cornerRadius: appearance.cornerRadius * layout.scale, style: .continuous))
                    .shadow(color: .black.opacity(appearance.shadowEnabled ? appearance.shadowOpacity : 0),
                            radius: appearance.shadowBlur * layout.scale, y: appearance.shadowBlur * layout.scale * 0.35)
                    .position(x: imageRect.midX, y: imageRect.midY)
                ForEach(markup.annotations) { mark in
                    markView(mark, in: imageRect, selected: mark.id == markup.selectedID)
                }
                if let draft { markView(draft, in: imageRect, selected: false) }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: markup.activeTool == .select || markup.activeTool == .text ? 0 : 2)
                .onChanged { value in
                    handleChange(value, in: imageRect)
                }
                .onEnded { value in
                    handleEnd(value, in: imageRect)
                })
        }
        .accessibilityLabel("Screenshot markup canvas")
        .onChange(of: markup.activeTool) { _, _ in
            draft = nil
            movingID = nil
            originalMark = nil
            markup.selectedID = nil
        }
    }

    private func fittedRects(_ imageSize: CGSize, in size: CGSize) -> (image: CGRect, backdrop: CGRect, frame: CGRect, scale: CGFloat) {
        guard imageSize.width > 0, imageSize.height > 0 else { return (.zero, .zero, .zero, 1) }
        let pad = CGFloat(max(0, appearance.padding))
        let shadowInset: CGFloat = appearance.shadowEnabled ? CGFloat(max(0, appearance.shadowBlur)) * 2 : 0
        let frameSide: CGFloat = appearance.frame == .none ? 0 : appearance.frame == .phone ? 22 : 14
        let frameTop: CGFloat = appearance.frame == .none ? 0 : appearance.frame == .phone ? 42 : 28
        let scale = min(size.width / (imageSize.width + 2 * (pad + frameSide + shadowInset)),
                        size.height / (imageSize.height + 2 * (pad + frameSide + shadowInset) + frameTop))
        let inset = (pad + frameSide) * scale
        let image = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let backdropSize = CGSize(width: image.width + inset * 2, height: image.height + inset * 2 + frameTop * scale)
        let totalSize = CGSize(width: backdropSize.width + 2 * shadowInset * scale,
                               height: backdropSize.height + 2 * shadowInset * scale)
        let backdrop = CGRect(x: (size.width - totalSize.width) / 2 + shadowInset * scale,
                              y: (size.height - totalSize.height) / 2 + shadowInset * scale,
                              width: backdropSize.width, height: backdropSize.height)
        let imageRect = CGRect(x: backdrop.minX + inset, y: backdrop.minY + inset,
                               width: image.width, height: image.height)
        let frame = imageRect.insetBy(dx: -frameSide * scale, dy: -frameSide * scale).insetBy(dx: 0, dy: -frameTop * scale / 2)
        return (imageRect, backdrop, frame, scale)
    }

    private func normalized(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(x: min(1, max(0, (point.x - rect.minX) / rect.width)),
                y: min(1, max(0, (point.y - rect.minY) / rect.height)))
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
                                   points: markup.activeTool == .pen ? [point] : [], colorHex: markup.activeColorHex)
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

    @ViewBuilder
    private func markView(_ mark: ScreenshotMark, in rect: CGRect, selected: Bool) -> some View {
        let start = canvasPoint(mark.start, in: rect)
        let end = canvasPoint(mark.end, in: rect)
        let bounds = CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
                            width: abs(end.x - start.x), height: abs(end.y - start.y))
        ZStack(alignment: .topLeading) {
            switch mark.tool {
            case .arrow:
                ArrowMark(start: start, end: end, lineWidth: max(5, rect.width * 0.012), colorHex: mark.colorHex)
            case .shape:
                Rectangle().stroke(markColor(mark.colorHex), lineWidth: 3).frame(width: bounds.width, height: bounds.height)
                    .position(x: bounds.midX, y: bounds.midY)
            case .redact:
                Rectangle().fill(Color.black).frame(width: max(12, bounds.width), height: max(12, bounds.height))
                    .position(x: bounds.midX, y: bounds.midY)
            case .pen:
                Path { path in
                    let points = mark.points.map { canvasPoint($0, in: rect) }
                    guard let first = points.first else { return }
                    path.move(to: first)
                    points.dropFirst().forEach { path.addLine(to: $0) }
                }
                .stroke(markColor(mark.colorHex), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            case .text:
                Text(mark.text)
                    .font(.system(size: max(16, rect.width * 0.035), weight: .semibold))
                    .foregroundStyle(markColor(mark.colorHex))
                    .position(start)
            case .select:
                EmptyView()
            }
            if selected {
                Rectangle().stroke(Ink.accentText, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .frame(width: max(10, bounds.width), height: max(10, bounds.height))
                    .position(x: bounds.midX, y: bounds.midY)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: rect.width, height: rect.height, alignment: .topLeading)
        .position(x: rect.midX, y: rect.midY)
    }

    private func canvasPoint(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(x: point.x * rect.width, y: point.y * rect.height)
    }

    private func markColor(_ hex: String) -> Color { Color(nsColor: NSColor(hex: hex) ?? .systemRed) }
}

struct ArrowMark: View {
    let start: CGPoint
    let end: CGPoint
    let lineWidth: CGFloat
    let colorHex: String
    var body: some View {
        let angle = atan2(end.y - start.y, end.x - start.x)
        let headLength = max(18, lineWidth * 4)
        let halfWidth = lineWidth * 1.5
        let base = CGPoint(x: end.x - headLength * cos(angle), y: end.y - headLength * sin(angle))
        let left = CGPoint(x: base.x + halfWidth * sin(angle), y: base.y - halfWidth * cos(angle))
        let right = CGPoint(x: base.x - halfWidth * sin(angle), y: base.y + halfWidth * cos(angle))
        Path { path in
            path.move(to: start); path.addLine(to: base)
            path.move(to: left); path.addLine(to: end); path.addLine(to: right)
        }.stroke(Color(nsColor: NSColor(hex: colorHex) ?? .systemRed),
                 style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
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
                    let step: CGFloat = preset == .blueprint ? 32 : 7
                    if preset == .blueprint {
                        for x in stride(from: 0, through: size.width, by: step) {
                            var path = Path(); path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height))
                            context.stroke(path, with: .color(.white.opacity(0.16)), lineWidth: 1)
                        }
                        for y in stride(from: 0, through: size.height, by: step) {
                            var path = Path(); path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(path, with: .color(.white.opacity(0.16)), lineWidth: 1)
                        }
                    } else {
                        for x in stride(from: 0, through: size.width, by: step) {
                            for y in stride(from: 0, through: size.height, by: step) {
                                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)), with: .color(.white.opacity(0.10)))
                            }
                        }
                    }
                }
            }
        }
    }
}
