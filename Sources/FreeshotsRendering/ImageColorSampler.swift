import AppKit

public enum ImageColorSampler {
    public static func dominantColorHex(from image: NSImage) -> String? {
        var bounds = CGRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &bounds, context: nil, hints: nil) else { return nil }
        return dominantColorHex(from: cgImage)
    }

    public static func dominantColorHex(from image: CGImage) -> String? {
        let side = 32
        let bytesPerRow = side * 4
        var pixels = [UInt8](repeating: 0, count: side * bytesPerRow)
        let didRender = pixels.withUnsafeMutableBytes { storage -> Bool in
            guard let context = CGContext(data: storage.baseAddress, width: side, height: side,
                                          bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else {
                return false
            }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        guard didRender else {
            return nil
        }

        var counts: [Int: Int] = [:]
        var sums: [Int: (red: Int, green: Int, blue: Int)] = [:]
        for offset in stride(from: 0, to: pixels.count, by: 4) where pixels[offset + 3] > 32 {
            let red = Int(pixels[offset])
            let green = Int(pixels[offset + 1])
            let blue = Int(pixels[offset + 2])
            let key = ((red >> 4) << 8) | ((green >> 4) << 4) | (blue >> 4)
            counts[key, default: 0] += 1
            let previous = sums[key, default: (0, 0, 0)]
            sums[key] = (previous.red + red, previous.green + green, previous.blue + blue)
        }
        guard let dominant = counts.max(by: { $0.value < $1.value })?.key,
              let count = counts[dominant], let sum = sums[dominant], count > 0 else { return nil }
        return String(format: "%02X%02X%02X", sum.red / count, sum.green / count, sum.blue / count)
    }
}
