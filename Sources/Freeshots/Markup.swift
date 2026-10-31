import AppKit
import Observation
import SwiftUI

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
    @Environment(MarkupDocument.self) private var markup
    @State private var draft: ScreenshotMark?
    @State private var movingID: UUID?
    @State private var moveOrigin: CGPoint = .zero
    @State private var originalMark: ScreenshotMark?

    var body: some View {
        GeometryReader { geometry in
            let imageRect = fittedRect(image.size, in: geometry.size)
            ZStack(alignment: .topLeading) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: imageRect.width, height: imageRect.height)
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

    private func fittedRect(_ imageSize: CGSize, in size: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        let scale = min(size.width / imageSize.width, size.height / imageSize.height)
        let fitted = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(x: (size.width - fitted.width) / 2,
                      y: (size.height - fitted.height) / 2,
                      width: fitted.width, height: fitted.height)
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
                                   points: markup.activeTool == .pen ? [point] : [])
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
                Path { path in
                    let angle = atan2(end.y - start.y, end.x - start.x)
                    let head: CGFloat = 12
                    let left = CGPoint(x: end.x - head * cos(angle - .pi / 6), y: end.y - head * sin(angle - .pi / 6))
                    let right = CGPoint(x: end.x - head * cos(angle + .pi / 6), y: end.y - head * sin(angle + .pi / 6))
                    path.move(to: start); path.addLine(to: end)
                    path.move(to: left); path.addLine(to: end); path.addLine(to: right)
                }
                .stroke(Ink.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            case .shape:
                Rectangle().stroke(Ink.accent, lineWidth: 3).frame(width: bounds.width, height: bounds.height)
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
                .stroke(Ink.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            case .text:
                Text(mark.text)
                    .font(.system(size: max(16, rect.width * 0.035), weight: .semibold))
                    .foregroundStyle(Ink.accent)
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
}
