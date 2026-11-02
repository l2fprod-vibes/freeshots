import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import FreeshotsCore

@MainActor
public struct ScreenshotArtworkView: View {
    public let image: NSImage
    public let appearance: ScreenshotAppearance
    public let annotations: [ScreenshotMark]
    public let selectedID: UUID?
    public let draft: ScreenshotMark?
    public let selectionColor: Color

    @State private var windowColor: Color

    public init(image: NSImage, appearance: ScreenshotAppearance, annotations: [ScreenshotMark] = [],
                selectedID: UUID? = nil, draft: ScreenshotMark? = nil,
                selectionColor: Color = .accentColor) {
        self.image = image
        self.appearance = appearance
        self.annotations = annotations
        self.selectedID = selectedID
        self.draft = draft
        self.selectionColor = selectionColor
        let hex = ImageColorSampler.dominantColorHex(from: image)
        self._windowColor = State(initialValue: Color(nsColor: NSColor(hex: hex ?? "") ?? .windowBackgroundColor))
    }

    public var body: some View {
        GeometryReader { geometry in
            let layout = fittedRects(image.size, in: geometry.size)
            ZStack(alignment: .topLeading) {
                BackdropPreview(preset: appearance.backdrop)
                    .frame(width: layout.backdrop.width, height: layout.backdrop.height)
                    .clipShape(RoundedRectangle(cornerRadius: appearance.backdropCornerRadius * layout.scale, style: .continuous))
                    .position(x: layout.backdrop.midX, y: layout.backdrop.midY)
                if appearance.frame != .none {
                    DeviceFramePreview(frame: appearance.frame, frameRect: layout.frame, scale: layout.scale,
                                       windowColor: windowColor)
                        .shadow(color: .black.opacity(appearance.shadowEnabled ? appearance.shadowOpacity : 0),
                                radius: appearance.shadowBlur * layout.scale,
                                y: appearance.shadowBlur * layout.scale * 0.35)
                        .position(x: layout.frame.midX, y: layout.frame.midY)
                }
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: layout.image.width, height: layout.image.height)
                    .clipShape(RoundedRectangle(cornerRadius: screenshotCornerRadius * layout.scale, style: .continuous))
                    .shadow(color: .black.opacity(appearance.shadowEnabled && appearance.frame == .none ? appearance.shadowOpacity : 0),
                            radius: appearance.shadowBlur * layout.scale, y: appearance.shadowBlur * layout.scale * 0.35)
                    .position(x: layout.image.midX, y: layout.image.midY)
                ForEach(annotations) { mark in
                    markView(mark, in: layout.image, selected: mark.id == selectedID)
                }
                if let draft { markView(draft, in: layout.image, selected: false) }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onChange(of: ObjectIdentifier(image)) { _, _ in
            let hex = ImageColorSampler.dominantColorHex(from: image)
            windowColor = Color(nsColor: NSColor(hex: hex ?? "") ?? .windowBackgroundColor)
        }
    }

    public static func imageRect(imageSize: CGSize, in size: CGSize, appearance: ScreenshotAppearance) -> CGRect {
        fittedRects(imageSize, in: size, appearance: appearance).image
    }

    private var screenshotCornerRadius: CGFloat {
        let configured = CGFloat(max(0, appearance.cornerRadius))
        return appearance.frame == .window ? max(configured, 8) : configured
    }

    private func fittedRects(_ imageSize: CGSize, in size: CGSize) -> (image: CGRect, backdrop: CGRect, frame: CGRect, scale: CGFloat) {
        Self.fittedRects(imageSize, in: size, appearance: appearance)
    }

    private static func fittedRects(_ imageSize: CGSize, in size: CGSize, appearance: ScreenshotAppearance) -> (image: CGRect, backdrop: CGRect, frame: CGRect, scale: CGFloat) {
        guard imageSize.width > 0, imageSize.height > 0 else { return (.zero, .zero, .zero, 1) }
        let pad = CGFloat(max(0, appearance.padding))
        let frameSide: CGFloat = appearance.frame == .phone ? 22 : appearance.frame == .mac ? 14 : appearance.frame == .window ? 2 : 0
        let frameTop: CGFloat = appearance.frame == .phone ? 42 : appearance.frame == .mac ? 28 : appearance.frame == .window ? 38 : 0
        let compositionSize = appearance.compositionSize(for: imageSize)
        let outputSize = appearance.outputSize(for: imageSize)
        let ratioInset = CGSize(width: (outputSize.width - compositionSize.width) / 2,
                                height: (outputSize.height - compositionSize.height) / 2)
        let scale = min(size.width / outputSize.width, size.height / outputSize.height)
        let inset = (pad + frameSide) * scale
        let image = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let backdropSize = CGSize(width: image.width + inset * 2 + 2 * ratioInset.width * scale,
                                  height: image.height + inset * 2 + frameTop * scale + 2 * ratioInset.height * scale)
        let backdrop = CGRect(x: (size.width - outputSize.width * scale) / 2,
                              y: (size.height - outputSize.height * scale) / 2,
                              width: backdropSize.width, height: backdropSize.height)
        let imageRect = CGRect(x: backdrop.minX + inset + ratioInset.width * scale,
                               y: backdrop.minY + inset + frameTop * scale + ratioInset.height * scale,
                               width: image.width, height: image.height)
        let frame = CGRect(x: imageRect.minX - frameSide * scale, y: imageRect.minY - frameSide * scale - frameTop * scale,
                           width: imageRect.width + 2 * frameSide * scale,
                           height: imageRect.height + 2 * frameSide * scale + frameTop * scale)
        return (imageRect, backdrop, frame, scale)
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
                ArrowMark(start: start, end: end, lineWidth: max(5, rect.width * 0.012), colorHex: mark.colorHex, style: mark.arrowStyle)
            case .shape:
                Rectangle().stroke(markColor(mark.colorHex), lineWidth: 3).frame(width: bounds.width, height: bounds.height)
                    .position(x: bounds.midX, y: bounds.midY)
            case .redact:
                Rectangle().fill(markColor(mark.colorHex)).frame(width: max(12, bounds.width), height: max(12, bounds.height))
                    .position(x: bounds.midX, y: bounds.midY)
            case .blur:
                if let pixelatedImage = Self.pixelated(image) {
                    Image(nsImage: pixelatedImage)
                        .resizable().interpolation(.none)
                        .frame(width: rect.width, height: rect.height)
                        .mask {
                            Rectangle()
                                .frame(width: max(1, bounds.width), height: max(1, bounds.height))
                                .position(x: bounds.midX, y: bounds.midY)
                        }
                        .frame(width: rect.width, height: rect.height, alignment: .topLeading)
                        .position(x: rect.midX, y: rect.midY)
                }
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
                Rectangle().stroke(selectionColor, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
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

    private static func pixelated(_ image: NSImage) -> NSImage? {
        var imageRect = CGRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil) else { return nil }
        let source = CIImage(cgImage: cgImage)
        let filter = CIFilter.pixellate()
        filter.inputImage = source
        filter.scale = 14
        guard let output = filter.outputImage?.cropped(to: source.extent),
              let result = CIContext().createCGImage(output, from: source.extent) else { return nil }
        return NSImage(cgImage: result, size: image.size)
    }
}

private struct DeviceFramePreview: View {
    let frame: DeviceFrame
    let frameRect: CGRect
    let scale: CGFloat
    let windowColor: Color

    var body: some View {
        let radius: CGFloat = frame == .phone ? 48 : frame == .window ? 10 : 18
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: radius * scale, style: .continuous)
                .fill(frame == .window ? windowColor : Color(white: 0.08))
            if frame == .window {
                VStack(spacing: 0) {
                    HStack(spacing: 8 * scale) {
                        Circle().fill(Color(nsColor: .systemRed))
                        Circle().fill(Color(nsColor: .systemYellow))
                        Circle().fill(Color(nsColor: .systemGreen))
                        Spacer(minLength: 0)
                    }
                    .frame(height: 12 * scale).padding(.horizontal, 10 * scale)
                    .frame(height: 38 * scale)
                    Rectangle().fill(Color(nsColor: .separatorColor).opacity(0.35)).frame(height: 1)
                    Spacer(minLength: 0)
                }
                .clipShape(RoundedRectangle(cornerRadius: radius * scale, style: .continuous))
            } else if frame == .phone {
                Capsule().fill(Color(white: 0.28)).frame(width: 64 * scale, height: 5 * scale)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 12 * scale)
            } else if frame == .mac {
                HStack(spacing: 7 * scale) {
                    Circle().fill(Color(nsColor: .systemRed))
                    Circle().fill(Color(nsColor: .systemYellow))
                    Circle().fill(Color(nsColor: .systemGreen))
                }
                .frame(width: 26 * scale, height: 7 * scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, 12 * scale).padding(.top, 10 * scale)
            }
        }
        .frame(width: frameRect.width, height: frameRect.height)
    }
}

private struct ArrowMark: View {
    let start: CGPoint
    let end: CGPoint
    let lineWidth: CGFloat
    let colorHex: String
    let style: ArrowStyle

    var body: some View {
        let angle = atan2(end.y - start.y, end.x - start.x)
        let headLength = max(18, lineWidth * 4)
        let halfWidth = lineWidth * 1.5
        let base = CGPoint(x: end.x - headLength * cos(angle), y: end.y - headLength * sin(angle))
        let left = CGPoint(x: base.x + halfWidth * sin(angle), y: base.y - halfWidth * cos(angle))
        let right = CGPoint(x: base.x - halfWidth * sin(angle), y: base.y + halfWidth * cos(angle))
        let color = Color(nsColor: NSColor(hex: colorHex) ?? .systemRed)
        let shaftEnd = base
        ZStack {
            Path { path in
                path.move(to: start); path.addLine(to: shaftEnd)
                if style == .double {
                    let reverseBase = CGPoint(x: start.x + headLength * cos(angle), y: start.y + headLength * sin(angle))
                    let reverseLeft = CGPoint(x: reverseBase.x - halfWidth * sin(angle), y: reverseBase.y + halfWidth * cos(angle))
                    let reverseRight = CGPoint(x: reverseBase.x + halfWidth * sin(angle), y: reverseBase.y - halfWidth * cos(angle))
                    path.move(to: reverseLeft); path.addLine(to: start); path.addLine(to: reverseRight)
                }
                if style == .open || style == .dashed {
                    path.move(to: left); path.addLine(to: end); path.addLine(to: right)
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round,
                                             dash: style == .dashed ? [lineWidth * 2, lineWidth * 1.5] : []))
            if style == .solid || style == .double {
                Path { path in
                    path.move(to: end); path.addLine(to: left); path.addLine(to: right); path.closeSubpath()
                    if style == .double {
                        let reverseBase = CGPoint(x: start.x + headLength * cos(angle), y: start.y + headLength * sin(angle))
                        let reverseLeft = CGPoint(x: reverseBase.x - halfWidth * sin(angle), y: reverseBase.y + halfWidth * cos(angle))
                        let reverseRight = CGPoint(x: reverseBase.x + halfWidth * sin(angle), y: reverseBase.y - halfWidth * cos(angle))
                        path.move(to: start); path.addLine(to: reverseLeft); path.addLine(to: reverseRight); path.closeSubpath()
                    }
                }.fill(color)
            }
        }
    }
}

private struct BackdropPreview: View {
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

extension NSColor {
    convenience init?(hex: String) {
        guard let value = UInt32(hex, radix: 16) else { return nil }
        self.init(calibratedRed: CGFloat((value >> 16) & 255) / 255,
                  green: CGFloat((value >> 8) & 255) / 255,
                  blue: CGFloat(value & 255) / 255, alpha: 1)
    }
}
