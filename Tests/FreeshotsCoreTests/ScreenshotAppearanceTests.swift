import Foundation
import Testing
@testable import FreeshotsCore

@Test("Backdrop presets expose stable names and color stops")
func backdropPresetsHaveColors() {
    #expect(BackdropPreset.allCases.map(\.title).contains("Ocean"))
    #expect(BackdropPreset.ocean.colors.count == 2)
    #expect(BackdropPreset.paper.colors.count == 1)
    #expect(BackdropPreset.transparent.colors.isEmpty)
    #expect(BackdropPreset.linen.texture)
}

@Test("Appearance settings round trip through local preference encoding")
func appearanceCodableRoundTrip() throws {
    let value = ScreenshotAppearance(backdrop: .blueprint, padding: 96, cornerRadius: 32,
                                     shadowEnabled: true, shadowBlur: 36, shadowOpacity: 0.42,
                                     frame: .mac, aspectRatio: .fourByThree)
    let data = try JSONEncoder().encode(value)
    #expect(try JSONDecoder().decode(ScreenshotAppearance.self, from: data) == value)
}

@Test("Aspect ratios add centered space without cropping image pixels")
func aspectRatiosExpandCanvas() {
    let screenshot = CGSize(width: 1200, height: 800)
    let square = ScreenshotAppearance(padding: 0, shadowEnabled: false, aspectRatio: .square)
    let widescreen = ScreenshotAppearance(padding: 0, shadowEnabled: false, aspectRatio: .sixteenByNine)
    #expect(square.outputSize(for: screenshot).width == 1200)
    #expect(square.outputSize(for: screenshot).height == 1200)
    let photoRatio = ScreenshotAppearance(padding: 0, shadowEnabled: false, aspectRatio: .fourByThree)
    #expect(photoRatio.outputSize(for: screenshot).width == 1200)
    #expect(photoRatio.outputSize(for: screenshot).height == 900)
    let composition = square.compositionSize(for: screenshot)
    let output = square.outputSize(for: screenshot)
    #expect((output.height - composition.height) / 2 == 200)
    #expect(abs(widescreen.outputSize(for: screenshot).width - 1_422.222) < 0.01)
    #expect(widescreen.outputSize(for: screenshot).height == 800)

    let portrait = ScreenshotAppearance(padding: 0, shadowEnabled: false, aspectRatio: .sixteenByNine)
    let portraitSize = portrait.outputSize(for: CGSize(width: 800, height: 1200))
    #expect(portraitSize.width == 800)
    #expect(abs(portraitSize.height - 1_422.222) < 0.01)
}

@Test("Older appearance preferences default to original aspect ratio")
func olderAppearancePreferencesDecode() throws {
    let data = #"{"backdrop":"paper","padding":40,"cornerRadius":12,"shadowEnabled":false,"shadowBlur":8,"shadowOpacity":0.2,"frame":"window"}"#.data(using: .utf8)!
    let value = try JSONDecoder().decode(ScreenshotAppearance.self, from: data)
    #expect(value.aspectRatio == .original)
    #expect(value.backdrop == .paper)
    #expect(value.frame == .window)
}

@Test("Export canvas reserves configured inset and device frame")
func outputSizeIncludesPaddingAndFrame() {
    let screenshot = CGSize(width: 1200, height: 800)
    let plain = ScreenshotAppearance(padding: 0, cornerRadius: 0, shadowEnabled: false, frame: .none)
    let framed = ScreenshotAppearance(padding: 80, shadowEnabled: false, frame: .phone)
    #expect(plain.outputSize(for: screenshot).width == screenshot.width)
    #expect(plain.outputSize(for: screenshot).height == screenshot.height)
    #expect(framed.outputSize(for: screenshot).width == 1404)
    #expect(framed.outputSize(for: screenshot).height == 1046)
}

@Test("Appearance values remain in a usable range")
func appearanceClampsPaddingForGeometry() {
    let value = ScreenshotAppearance(padding: -10, shadowEnabled: false)
    #expect(value.outputSize(for: CGSize(width: 500, height: 300)).width == 500)
    #expect(value.outputSize(for: CGSize(width: 500, height: 300)).height == 300)
}

@Test("Shadow blur does not resize the output canvas")
func shadowDoesNotResizeCanvas() {
    let imageSize = CGSize(width: 500, height: 300)
    let disabled = ScreenshotAppearance(padding: 0, shadowEnabled: false, shadowBlur: 0)
    let enabled = ScreenshotAppearance(padding: 0, shadowEnabled: true, shadowBlur: 80)
    #expect(enabled.outputSize(for: imageSize) == disabled.outputSize(for: imageSize))
    #expect(enabled.compositionSize(for: imageSize) == disabled.compositionSize(for: imageSize))
}

@Test("Window frame reserves a title bar and slim border")
func windowFrameOutputSize() {
    let value = ScreenshotAppearance(padding: 0, shadowEnabled: false, frame: .window)
    let size = value.outputSize(for: CGSize(width: 500, height: 300))
    #expect(size.width == 504)
    #expect(size.height == 342)
}
