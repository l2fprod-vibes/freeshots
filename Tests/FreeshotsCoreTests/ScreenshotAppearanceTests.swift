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
                                     frame: .mac)
    let data = try JSONEncoder().encode(value)
    #expect(try JSONDecoder().decode(ScreenshotAppearance.self, from: data) == value)
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

@Test("Enabled shadow reserves transparent canvas around its blur")
func shadowReservesCanvasSpace() {
    let value = ScreenshotAppearance(padding: 0, shadowEnabled: true, shadowBlur: 20)
    let size = value.outputSize(for: CGSize(width: 500, height: 300))
    #expect(size.width == 580)
    #expect(size.height == 380)
}
