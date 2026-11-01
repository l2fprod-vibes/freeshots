import AppKit
import SwiftUI
import FreeshotsCore

@MainActor
public enum ScreenshotRenderer {
    public static func pngData(image: NSImage, annotations: [ScreenshotMark], appearance: ScreenshotAppearance = .defaults) -> Data? {
        var proposedRect = CGRect(origin: .zero, size: image.size)
        guard let source = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil),
              image.size.width > 0, image.size.height > 0 else { return nil }

        let outputSize = appearance.outputSize(for: image.size)
        let scaleX = CGFloat(source.width) / image.size.width
        let scaleY = CGFloat(source.height) / image.size.height
        guard outputSize.width > 0, outputSize.height > 0,
              scaleX.isFinite, scaleY.isFinite, scaleX > 0, scaleY > 0 else { return nil }

        let artwork = ScreenshotArtworkView(image: image, appearance: appearance, annotations: annotations)
            .frame(width: outputSize.width, height: outputSize.height)
        let renderer = ImageRenderer(content: artwork)
        renderer.proposedSize = ProposedViewSize(outputSize)
        renderer.scale = max(scaleX, scaleY)
        // The preview leaves the shadow inset outside the backdrop transparent.
        renderer.isOpaque = false

        guard let renderedImage = renderer.nsImage,
              let tiff = renderedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
