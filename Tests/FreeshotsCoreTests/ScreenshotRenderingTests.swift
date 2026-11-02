import AppKit
import FreeshotsCore
import FreeshotsRendering
import Testing

@MainActor
@Test("Renderer emits a full resolution PNG with the requested composition")
func rendererEmitsFullResolutionPNG() throws {
    let source = sampleImage(width: 40, height: 30, color: .systemBlue)
    let appearance = ScreenshotAppearance(backdrop: .paper, padding: 5, cornerRadius: 0,
                                          backdropCornerRadius: 0, shadowEnabled: false,
                                          frame: .window, aspectRatio: .square)

    let data = try #require(ScreenshotRenderer.pngData(image: source, annotations: [], appearance: appearance))
    let bitmap = try #require(NSBitmapImageRep(data: data))

    #expect(bitmap.pixelsWide == 82)
    #expect(bitmap.pixelsHigh == 82)
    #expect(bitmap.colorAt(x: 0, y: 0)?.alphaComponent == 1)
    #expect(bitmap.colorAt(x: 0, y: 0)?.redComponent ?? 0 > 0.8)
}

@MainActor
@Test("Export renders the preview artwork at full composition dimensions")
func exportRendersPreviewArtworkDimensions() throws {
    let source = sampleImage(width: 40, height: 30, color: .systemBlue)
    let appearance = ScreenshotAppearance(backdrop: .lagoon, padding: 16, cornerRadius: 12,
                                          shadowEnabled: true, shadowBlur: 8,
                                          frame: .phone, aspectRatio: .fourByThree)

    let export = try #require(ScreenshotRenderer.pngData(image: source, annotations: [], appearance: appearance))
    let exportedBitmap = try #require(NSBitmapImageRep(data: export))
    let expectedSize = appearance.outputSize(for: source.size)

    #expect(exportedBitmap.pixelsWide == Int(expectedSize.width.rounded(.up)))
    #expect(exportedBitmap.pixelsHigh == Int(expectedSize.height.rounded(.up)))
}

@MainActor
@Test("Shadow blur does not add a black margin around the rendered backdrop")
func shadowDoesNotAddOutputMargin() throws {
    let source = sampleImage(width: 40, height: 30, color: .systemBlue)
    let appearance = ScreenshotAppearance(backdrop: .blueprint, padding: 0, cornerRadius: 0,
                                          backdropCornerRadius: 0,
                                          shadowEnabled: true, shadowBlur: 8, shadowOpacity: 0.2,
                                          frame: .none)

    let data = try #require(ScreenshotRenderer.pngData(image: source, annotations: [], appearance: appearance))
    let bitmap = try #require(NSBitmapImageRep(data: data))
    let outerEdge = try #require(bitmap.colorAt(x: 0, y: 0)?.usingColorSpace(.deviceRGB))
    let backdrop = try #require(bitmap.colorAt(x: 16, y: 16)?.usingColorSpace(.deviceRGB))

    #expect(outerEdge.alphaComponent > 0.95)
    #expect(backdrop.alphaComponent > 0.95)
}

@MainActor
@Test("Shadow is drawn around the screenshot without changing canvas bounds")
func screenshotShadowStaysWithinCanvas() throws {
    let source = sampleImage(width: 40, height: 30, color: .systemBlue)
    let noShadow = ScreenshotAppearance(backdrop: .transparent, padding: 24, cornerRadius: 0,
                                        backdropCornerRadius: 0, shadowEnabled: false,
                                        frame: .none)
    let withShadow = ScreenshotAppearance(backdrop: .transparent, padding: 24, cornerRadius: 0,
                                          backdropCornerRadius: 0, shadowEnabled: true,
                                          shadowBlur: 8, shadowOpacity: 0.8, frame: .none)

    let plainPNG = try #require(ScreenshotRenderer.pngData(image: source, annotations: [], appearance: noShadow))
    let shadowPNG = try #require(ScreenshotRenderer.pngData(image: source, annotations: [], appearance: withShadow))
    let plain = try #require(NSBitmapImageRep(data: plainPNG))
    let shadow = try #require(NSBitmapImageRep(data: shadowPNG))
    let plainEdge = try #require(plain.colorAt(x: 19, y: 45)?.usingColorSpace(.deviceRGB))
    let shadowEdge = try #require(shadow.colorAt(x: 19, y: 45)?.usingColorSpace(.deviceRGB))

    #expect(plain.pixelsWide == shadow.pixelsWide)
    #expect(plain.pixelsHigh == shadow.pixelsHigh)
    #expect(plainEdge.alphaComponent < 0.05)
    #expect(shadowEdge.alphaComponent > 0.05)
}

@MainActor
@Test("A device frame receives the configured shadow")
func deviceFrameReceivesShadow() throws {
    let source = sampleImage(width: 40, height: 30, color: .systemBlue)
    let appearance = ScreenshotAppearance(backdrop: .transparent, padding: 28, cornerRadius: 0,
                                           backdropCornerRadius: 0, shadowEnabled: true,
                                           shadowBlur: 8, shadowOpacity: 0.8, frame: .phone)

    let data = try #require(ScreenshotRenderer.pngData(image: source, annotations: [], appearance: appearance))
    let bitmap = try #require(NSBitmapImageRep(data: data))
    let outsideFrame = try #require(bitmap.colorAt(x: 22, y: 70)?.usingColorSpace(.deviceRGB))

    #expect(outsideFrame.alphaComponent > 0.05)
}

@MainActor
@Test("Renderer applies redaction to the exported pixels")
func rendererAppliesRedaction() throws {
    let source = sampleImage(width: 40, height: 30, color: .systemBlue)
    let appearance = ScreenshotAppearance(backdrop: .transparent, padding: 5, cornerRadius: 0,
                                          shadowEnabled: false, frame: .none)
    let redaction = ScreenshotMark(tool: .redact, start: CGPoint(x: 0.25, y: 0.25),
                                   end: CGPoint(x: 0.75, y: 0.75), colorHex: "00FF00")

    let data = try #require(ScreenshotRenderer.pngData(image: source, annotations: [redaction], appearance: appearance))
    let bitmap = try #require(NSBitmapImageRep(data: data))
    let pixel = try #require(bitmap.colorAt(x: 20, y: 15)?.usingColorSpace(.deviceRGB))

    #expect(pixel.redComponent < 0.05)
    #expect(pixel.greenComponent > 0.9)
    #expect(pixel.blueComponent < 0.05)
    #expect(pixel.alphaComponent > 0.95)
}

@MainActor
@Test("Renderer preserves source pixels outside markup")
func rendererPreservesUnmarkedPixelsAndTransparency() throws {
    let source = sampleImage(width: 40, height: 30, color: .systemBlue)
    let appearance = ScreenshotAppearance(backdrop: .transparent, padding: 0, cornerRadius: 0,
                                          shadowEnabled: false, frame: .none)
    let data = try #require(ScreenshotRenderer.pngData(image: source, annotations: [], appearance: appearance))
    let bitmap = try #require(NSBitmapImageRep(data: data))
    let sourcePixel = try #require(bitmap.colorAt(x: 25, y: 20)?.usingColorSpace(.deviceRGB))

    #expect(bitmap.pixelsWide == 40)
    #expect(bitmap.pixelsHigh == 30)
    #expect(sourcePixel.blueComponent > 0.7)
    #expect(sourcePixel.alphaComponent > 0.9)
}

@MainActor
private func sampleImage(width: Int, height: Int, color: NSColor) -> NSImage {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    color.setFill()
    NSBezierPath(rect: CGRect(x: 0, y: 0, width: width, height: height)).fill()
    NSGraphicsContext.restoreGraphicsState()
    return NSImage(cgImage: bitmap.cgImage!, size: NSSize(width: width, height: height))
}
