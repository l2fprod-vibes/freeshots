import Foundation
import CoreGraphics

public enum MarkupTool: String, CaseIterable, Identifiable, Sendable {
    case select, arrow, shape, text, pen, redact, blur
    public var id: Self { self }
    public var title: String { rawValue.capitalized }
    public var symbol: String {
        switch self {
        case .select: "cursorarrow"
        case .arrow: "arrow.up.right"
        case .shape: "rectangle"
        case .text: "textformat"
        case .pen: "pencil.tip"
        case .redact: "rectangle.fill"
        case .blur: "drop.halffull"
        }
    }
    public var shortcut: String {
        switch self {
        case .select: "V"
        case .arrow: "A"
        case .shape: "R"
        case .text: "T"
        case .pen: "P"
        case .redact: "G"
        case .blur: "B"
        }
    }
}

public enum ArrowStyle: String, CaseIterable, Identifiable, Sendable {
    case solid, open, dashed, double

    public var id: Self { self }
    public var title: String {
        switch self {
        case .solid: "Solid"
        case .open: "Open"
        case .dashed: "Dashed"
        case .double: "Double"
        }
    }
}

public struct ScreenshotMark: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var tool: MarkupTool
    public var start: CGPoint
    public var end: CGPoint
    public var points: [CGPoint]
    public var text: String
    public var colorHex: String
    public var arrowStyle: ArrowStyle

    public init(id: UUID = UUID(), tool: MarkupTool, start: CGPoint, end: CGPoint,
                points: [CGPoint] = [], text: String = "", colorHex: String = "E53935",
                arrowStyle: ArrowStyle = .solid) {
        self.id = id
        self.tool = tool
        self.start = start
        self.end = end
        self.points = points
        self.text = text
        self.colorHex = colorHex
        self.arrowStyle = arrowStyle
    }

    public var normalizedBounds: CGRect {
        if tool == .pen, !points.isEmpty {
            let xs = points.map(\.x), ys = points.map(\.y)
            let minX = xs.min() ?? 0
            let minY = ys.min() ?? 0
            let width = (xs.max() ?? 0) - minX
            let height = (ys.max() ?? 0) - minY
            return CGRect(x: minX, y: minY, width: width, height: height)
        }
        return CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
                      width: abs(end.x - start.x), height: abs(end.y - start.y))
    }

    public func offsetBy(_ delta: CGPoint) -> ScreenshotMark {
        var copy = self
        copy.start.x += delta.x; copy.start.y += delta.y
        copy.end.x += delta.x; copy.end.y += delta.y
        copy.points = points.map { CGPoint(x: $0.x + delta.x, y: $0.y + delta.y) }
        return copy
    }
}

extension ScreenshotMark {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.tool == rhs.tool &&
        lhs.start.x == rhs.start.x && lhs.start.y == rhs.start.y &&
        lhs.end.x == rhs.end.x && lhs.end.y == rhs.end.y &&
        lhs.points.elementsEqual(rhs.points, by: { $0.x == $1.x && $0.y == $1.y }) &&
        lhs.text == rhs.text && lhs.colorHex == rhs.colorHex && lhs.arrowStyle == rhs.arrowStyle
    }
}
