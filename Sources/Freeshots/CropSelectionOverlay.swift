import SwiftUI

struct CropSelectionOverlay: View {
    let imageRect: CGRect
    let canvasSize: CGSize
    let selection: CGRect
    let onChange: (CGRect) -> Void
    @State private var dragMode: CropDragMode?
    @State private var handleStart: CGRect?
    @FocusState private var keyboardFocused: Bool

    var body: some View {
        let selected = CGRect(x: imageRect.minX + selection.minX * imageRect.width,
                              y: imageRect.minY + selection.minY * imageRect.height,
                              width: selection.width * imageRect.width,
                              height: selection.height * imageRect.height)
        ZStack(alignment: .topLeading) {
            Path { path in
                path.addRect(imageRect)
                path.addRect(selected)
            }
            .fill(.black.opacity(0.48), style: FillStyle(eoFill: true))

            Rectangle().fill(.clear).contentShape(Rectangle())
                .frame(width: imageRect.width, height: imageRect.height)
                .position(x: imageRect.midX, y: imageRect.midY)
                .gesture(DragGesture(minimumDistance: 2, coordinateSpace: .named("cropSelectionCanvas"))
                    .onChanged { value in
                        let start = normalized(value.startLocation)
                        let point = normalized(value.location)
                        if dragMode == nil {
                            dragMode = selection.contains(start)
                                ? .move(start: start, selection: selection)
                                : .create(start: start)
                        }
                        switch dragMode {
                        case let .move(origin, initial):
                            var moved = initial.offsetBy(dx: point.x - origin.x, dy: point.y - origin.y)
                            moved.origin.x = min(max(0, moved.minX), 1 - moved.width)
                            moved.origin.y = min(max(0, moved.minY), 1 - moved.height)
                            onChange(moved)
                        case let .create(origin):
                            onChange(CGRect(x: min(origin.x, point.x), y: min(origin.y, point.y),
                                            width: abs(point.x - origin.x), height: abs(point.y - origin.y)))
                        case nil:
                            break
                        }
                    }
                    .onEnded { _ in dragMode = nil })

            Rectangle()
                .stroke(Color.accentColor, lineWidth: 2)
                .frame(width: selected.width, height: selected.height)
                .position(x: selected.midX, y: selected.midY)
                .accessibilityHidden(true)

            ForEach(CropHandle.allCases) { handle in
                Circle()
                    .fill(.clear)
                    .frame(width: 20, height: 20)
                    .overlay {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white)
                            .frame(width: 10, height: 10)
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.accentColor, lineWidth: 2))
                    }
                    .position(handle.position(in: selected))
                    .gesture(resizeGesture(handle))
                    .accessibilityLabel("Crop \(handle.title) handle")
            }

        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .coordinateSpace(name: "cropSelectionCanvas")
        .accessibilityLabel("Screenshot crop selection")
        .accessibilityValue("Left \(Int(selection.minX * 100))%, top \(Int(selection.minY * 100))%, width \(Int(selection.width * 100))%, height \(Int(selection.height * 100))%")
        .focusable()
        .focused($keyboardFocused)
        .onAppear { keyboardFocused = true }
        .onKeyPress(.leftArrow) { adjustWithKeyboard(dx: -1, dy: 0); return .handled }
        .onKeyPress(.rightArrow) { adjustWithKeyboard(dx: 1, dy: 0); return .handled }
        .onKeyPress(.upArrow) { adjustWithKeyboard(dx: 0, dy: -1); return .handled }
        .onKeyPress(.downArrow) { adjustWithKeyboard(dx: 0, dy: 1); return .handled }
    }

    private func adjustWithKeyboard(dx: CGFloat, dy: CGFloat) {
        var next = selection
        if NSEvent.modifierFlags.contains(.shift) {
            next.origin.x += dx * 0.01
            next.origin.y += dy * 0.01
            next.origin.x = min(max(0, next.minX), 1 - next.width)
            next.origin.y = min(max(0, next.minY), 1 - next.height)
        } else {
            next.size.width = min(max(0.02, next.width + dx * 0.01), 1 - next.minX)
            next.size.height = min(max(0.02, next.height + dy * 0.01), 1 - next.minY)
        }
        onChange(next)
    }

    private func normalized(_ point: CGPoint) -> CGPoint {
        CGPoint(x: min(1, max(0, (point.x - imageRect.minX) / imageRect.width)),
                y: min(1, max(0, (point.y - imageRect.minY) / imageRect.height)))
    }

    private func resizeGesture(_ handle: CropHandle) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if handleStart == nil { handleStart = selection }
                guard let handleStart else { return }
                onChange(handleStart.resized(by: CGSize(width: value.translation.width / imageRect.width,
                                                        height: value.translation.height / imageRect.height),
                                             at: handle))
            }
            .onEnded { _ in handleStart = nil }
    }
}

private enum CropDragMode {
    case move(start: CGPoint, selection: CGRect)
    case create(start: CGPoint)
}

private enum CropHandle: String, CaseIterable, Identifiable {
    case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left
    var id: Self { self }
    var title: String { rawValue.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).lowercased() }

    func position(in rect: CGRect) -> CGPoint {
        switch self {
        case .topLeft: CGPoint(x: rect.minX, y: rect.minY)
        case .top: CGPoint(x: rect.midX, y: rect.minY)
        case .topRight: CGPoint(x: rect.maxX, y: rect.minY)
        case .right: CGPoint(x: rect.maxX, y: rect.midY)
        case .bottomRight: CGPoint(x: rect.maxX, y: rect.maxY)
        case .bottom: CGPoint(x: rect.midX, y: rect.maxY)
        case .bottomLeft: CGPoint(x: rect.minX, y: rect.maxY)
        case .left: CGPoint(x: rect.minX, y: rect.midY)
        }
    }
}

private extension CGRect {
    func resized(by delta: CGSize, at handle: CropHandle) -> CGRect {
        let movesLeft = [.topLeft, .bottomLeft, .left].contains(handle)
        let movesRight = [.topRight, .bottomRight, .right].contains(handle)
        let movesTop = [.topLeft, .topRight, .top].contains(handle)
        let movesBottom = [.bottomLeft, .bottomRight, .bottom].contains(handle)
        let left = movesLeft ? min(max(0, minX + delta.width), maxX - 0.02) : minX
        let right = movesRight ? max(min(1, maxX + delta.width), left + 0.02) : maxX
        let top = movesTop ? min(max(0, minY + delta.height), maxY - 0.02) : minY
        let bottom = movesBottom ? max(min(1, maxY + delta.height), top + 0.02) : maxY
        return CGRect(x: left, y: top, width: right - left, height: bottom - top)
    }
}

