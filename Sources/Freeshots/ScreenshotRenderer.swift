import AppKit

enum ScreenshotRenderer {
    @MainActor
    static func pngData(image: NSImage, annotations: [ScreenshotMark]) -> Data? {
        var proposedRect = CGRect(origin: .zero, size: image.size)
        guard let source = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else { return nil }
        guard !annotations.isEmpty else {
            return NSBitmapImageRep(cgImage: source).representation(using: .png, properties: [:])
        }

        let width = source.width
        let height = source.height
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
                                            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                            isPlanar: false, colorSpaceName: .deviceRGB,
                                            bytesPerRow: 0, bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: bitmap) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        context.cgContext.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
        for mark in annotations { draw(mark, width: CGFloat(width), height: CGFloat(height)) }
        NSGraphicsContext.restoreGraphicsState()
        return bitmap.representation(using: .png, properties: [:])
    }

    @MainActor
    private static func draw(_ mark: ScreenshotMark, width: CGFloat, height: CGFloat) {
        let start = pixelPoint(mark.start, width: width, height: height)
        let end = pixelPoint(mark.end, width: width, height: height)
        let rect = CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
                          width: abs(end.x - start.x), height: abs(end.y - start.y))
        let accent = NSColor(calibratedRed: 0.84, green: 1, blue: 0.31, alpha: 1)
        switch mark.tool {
        case .arrow:
            let path = NSBezierPath()
            path.lineWidth = max(3, width * 0.003)
            path.lineCapStyle = .round
            path.move(to: start); path.line(to: end)
            let angle = atan2(end.y - start.y, end.x - start.x)
            let head = max(12, width * 0.012)
            let left = CGPoint(x: end.x - head * cos(angle - .pi / 6), y: end.y - head * sin(angle - .pi / 6))
            let right = CGPoint(x: end.x - head * cos(angle + .pi / 6), y: end.y - head * sin(angle + .pi / 6))
            path.move(to: left); path.line(to: end); path.line(to: right)
            accent.setStroke(); path.stroke()
        case .shape:
            let path = NSBezierPath(rect: rect)
            path.lineWidth = max(3, width * 0.003)
            accent.setStroke(); path.stroke()
        case .redact:
            NSColor.black.setFill()
            NSBezierPath(rect: rect).fill()
        case .pen:
            guard let first = mark.points.first else { return }
            let path = NSBezierPath()
            path.lineWidth = max(3, width * 0.003)
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.move(to: pixelPoint(first, width: width, height: height))
            mark.points.dropFirst().forEach { path.line(to: pixelPoint($0, width: width, height: height)) }
            accent.setStroke(); path.stroke()
        case .text:
            let font = NSFont.systemFont(ofSize: max(16, width * 0.035), weight: .semibold)
            let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: accent]
            (mark.text as NSString).draw(at: start, withAttributes: attributes)
        case .select:
            break
        }
    }

    private static func pixelPoint(_ point: CGPoint, width: CGFloat, height: CGFloat) -> CGPoint {
        CGPoint(x: point.x * width, y: height - point.y * height)
    }
}
