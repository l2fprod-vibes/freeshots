import AppKit
import FreeshotsCore

@MainActor
enum ScreenshotRenderer {
    static func pngData(image: NSImage, annotations: [ScreenshotMark], appearance: ScreenshotAppearance = .defaults) -> Data? {
        var proposed = CGRect(origin: .zero, size: image.size)
        guard let source = image.cgImage(forProposedRect: &proposed, context: nil, hints: nil) else { return nil }
        let sourceSize = CGSize(width: source.width, height: source.height)
        let canvasSize = appearance.outputSize(for: sourceSize)
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(canvasSize.width), pixelsHigh: Int(canvasSize.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: bitmap) else { return nil }

        let pad = CGFloat(max(0, appearance.padding))
        let shadowInset = appearance.shadowEnabled ? ceil(CGFloat(max(0, appearance.shadowBlur)) * 2) : 0
        let frameSide: CGFloat = appearance.frame == .none ? 0 : appearance.frame == .phone ? 22 : 14
        let imageRect = CGRect(x: pad + shadowInset + frameSide, y: pad + shadowInset + frameSide,
                               width: sourceSize.width, height: sourceSize.height)
        let radius = CGFloat(max(0, appearance.cornerRadius))
        let fullRect = CGRect(origin: .zero, size: canvasSize)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        drawBackdrop(appearance.backdrop, in: fullRect, context: context.cgContext)
        drawDeviceFrame(appearance.frame, imageRect: imageRect, context: context.cgContext)

        let imagePath = NSBezierPath(roundedRect: imageRect, xRadius: radius, yRadius: radius)
        if appearance.shadowEnabled && appearance.shadowOpacity > 0 {
            context.cgContext.saveGState()
            context.cgContext.setShadow(offset: CGSize(width: 0, height: -CGFloat(appearance.shadowBlur) * 0.35),
                                       blur: CGFloat(appearance.shadowBlur),
                                       color: NSColor.black.withAlphaComponent(CGFloat(appearance.shadowOpacity)).cgColor)
            context.cgContext.addPath(CGPath(roundedRect: imageRect, cornerWidth: radius, cornerHeight: radius, transform: nil))
            context.cgContext.setFillColor(NSColor.white.cgColor)
            context.cgContext.fillPath()
            context.cgContext.restoreGState()
        }
        imagePath.addClip()
        context.cgContext.draw(source, in: imageRect)

        if radius > 0 {
            imagePath.addClip()
        }
        for mark in annotations { draw(mark, width: sourceSize.width, height: sourceSize.height, origin: imageRect.origin) }
        context.cgContext.restoreGState()

        if radius > 0 {
            NSColor.white.withAlphaComponent(0.2).setStroke()
            let border = NSBezierPath(roundedRect: imageRect, xRadius: radius, yRadius: radius)
            border.lineWidth = 1
            border.stroke()
        }
        if appearance.frame != .none { drawDeviceDetails(appearance.frame, imageRect: imageRect, context: context) }
        NSGraphicsContext.restoreGraphicsState()
        return bitmap.representation(using: .png, properties: [:])
    }

    private static func drawBackdrop(_ preset: BackdropPreset, in rect: CGRect, context: CGContext) {
        let colors = preset.colors.compactMap { NSColor(hex: $0)?.cgColor }
        guard !colors.isEmpty else { return }
        context.saveGState()
        if colors.count == 1 {
            context.setFillColor(colors[0]); context.fill(rect)
        } else if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) {
            context.drawLinearGradient(gradient, start: CGPoint(x: rect.minX, y: rect.minY), end: CGPoint(x: rect.maxX, y: rect.maxY), options: [])
        }
        if preset.texture {
            context.setStrokeColor(NSColor.white.withAlphaComponent(preset == .blueprint ? 0.16 : 0.07).cgColor)
            context.setFillColor(NSColor.white.withAlphaComponent(0.10).cgColor)
            context.setLineWidth(1)
            let step: CGFloat = preset == .blueprint ? 32 : 7
            if preset == .blueprint {
                stride(from: rect.minX, through: rect.maxX, by: step).forEach { x in
                    context.move(to: CGPoint(x: x, y: rect.minY)); context.addLine(to: CGPoint(x: x, y: rect.maxY))
                }
                stride(from: rect.minY, through: rect.maxY, by: step).forEach { y in
                    context.move(to: CGPoint(x: rect.minX, y: y)); context.addLine(to: CGPoint(x: rect.maxX, y: y))
                }
                context.strokePath()
            } else {
                stride(from: rect.minX, through: rect.maxX, by: step).forEach { x in
                    stride(from: rect.minY, through: rect.maxY, by: step).forEach { y in
                        context.fillEllipse(in: CGRect(x: x, y: y, width: 1, height: 1))
                    }
                }
            }
        }
        context.restoreGState()
    }

    private static func drawDeviceFrame(_ frame: DeviceFrame, imageRect: CGRect, context: CGContext) {
        guard frame != .none else { return }
        let inset: CGFloat = frame == .phone ? 22 : 14
        let top: CGFloat = frame == .phone ? 42 : 28
        let frameRect = imageRect.insetBy(dx: -inset, dy: -inset).insetBy(dx: 0, dy: -top / 2)
        let radius: CGFloat = frame == .phone ? 48 : 18
        context.saveGState()
        context.setFillColor(NSColor(calibratedWhite: 0.08, alpha: 1).cgColor)
        context.addPath(CGPath(roundedRect: frameRect, cornerWidth: radius, cornerHeight: radius, transform: nil))
        context.fillPath()
        context.restoreGState()
    }

    private static func drawDeviceDetails(_ frame: DeviceFrame, imageRect: CGRect, context: NSGraphicsContext) {
        if frame == .mac {
            let y = imageRect.maxY + 7
            [NSColor.systemRed, .systemYellow, .systemGreen].enumerated().forEach { index, color in
                color.setFill()
                NSBezierPath(ovalIn: CGRect(x: imageRect.minX - 2 + CGFloat(index) * 14, y: y, width: 7, height: 7)).fill()
            }
        } else if frame == .phone {
            NSColor(calibratedWhite: 0.28, alpha: 1).setFill()
            NSBezierPath(roundedRect: CGRect(x: imageRect.midX - 32, y: imageRect.maxY + 12, width: 64, height: 5), xRadius: 3, yRadius: 3).fill()
        }
    }

    private static func draw(_ mark: ScreenshotMark, width: CGFloat, height: CGFloat, origin: CGPoint) {
        let start = pixelPoint(mark.start, width: width, height: height, origin: origin)
        let end = pixelPoint(mark.end, width: width, height: height, origin: origin)
        let rect = CGRect(x: min(start.x, end.x), y: min(start.y, end.y), width: abs(end.x - start.x), height: abs(end.y - start.y))
        let color = NSColor(hex: mark.colorHex) ?? .systemRed
        switch mark.tool {
        case .arrow:
            let angle = atan2(end.y - start.y, end.x - start.x)
            let line = max(6, width * 0.009)
            let head = max(24, width * 0.035)
            let half = line * 1.6
            let base = CGPoint(x: end.x - head * cos(angle), y: end.y - head * sin(angle))
            let left = CGPoint(x: base.x + half * sin(angle), y: base.y - half * cos(angle))
            let right = CGPoint(x: base.x - half * sin(angle), y: base.y + half * cos(angle))
            let path = NSBezierPath(); path.lineWidth = line; path.lineCapStyle = .round
            path.move(to: start); path.line(to: base); path.move(to: left); path.line(to: end); path.line(to: right)
            color.setStroke(); path.stroke()
        case .shape:
            let path = NSBezierPath(rect: rect); path.lineWidth = max(3, width * 0.003); color.setStroke(); path.stroke()
        case .redact:
            NSColor.black.setFill(); NSBezierPath(rect: rect).fill()
        case .pen:
            guard let first = mark.points.first else { return }
            let path = NSBezierPath(); path.lineWidth = max(3, width * 0.003); path.lineCapStyle = .round; path.lineJoinStyle = .round
            path.move(to: pixelPoint(first, width: width, height: height, origin: origin))
            mark.points.dropFirst().forEach { path.line(to: pixelPoint($0, width: width, height: height, origin: origin)) }
            color.setStroke(); path.stroke()
        case .text:
            let font = NSFont.systemFont(ofSize: max(16, width * 0.035), weight: .semibold)
            (mark.text as NSString).draw(at: start, withAttributes: [.font: font, .foregroundColor: color])
        case .select: break
        }
    }

    private static func pixelPoint(_ point: CGPoint, width: CGFloat, height: CGFloat, origin: CGPoint) -> CGPoint {
        CGPoint(x: origin.x + point.x * width, y: origin.y + height - point.y * height)
    }
}
