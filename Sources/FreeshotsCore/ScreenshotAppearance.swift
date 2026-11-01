import Foundation

public enum BackdropPreset: String, CaseIterable, Codable, Sendable, Identifiable {
    case transparent, paper, ocean, violet, sunset, mint, graphite, linen, blueprint
    case coral, lagoon, lavender, amber, moss, sand, graphiteGrid, roseDots
    public var id: Self { self }
    public var title: String {
        switch self {
        case .transparent: "None"
        case .paper: "Paper"
        case .ocean: "Ocean"
        case .violet: "Violet"
        case .sunset: "Sunset"
        case .mint: "Mint"
        case .graphite: "Graphite"
        case .linen: "Linen"
        case .blueprint: "Blueprint"
        case .coral: "Coral"
        case .lagoon: "Lagoon"
        case .lavender: "Lavender"
        case .amber: "Amber"
        case .moss: "Moss"
        case .sand: "Sand"
        case .graphiteGrid: "Graphite Grid"
        case .roseDots: "Rose Dots"
        }
    }
    public var colors: [String] {
        switch self {
        case .transparent: []
        case .paper: ["F4F0E8"]
        case .ocean: ["3B82F6", "06B6D4"]
        case .violet: ["6D5DFB", "C084FC"]
        case .sunset: ["FB7185", "F59E0B"]
        case .mint: ["34D399", "A3E635"]
        case .graphite: ["30343B", "101319"]
        case .linen: ["E9E2D6", "CFC4B3"]
        case .blueprint: ["0F3D68", "2679A8"]
        case .coral: ["FF9A8B", "FF6A88"]
        case .lagoon: ["0F766E", "22D3EE"]
        case .lavender: ["8B7CF6", "E7A8E8"]
        case .amber: ["F59E0B", "FDE68A"]
        case .moss: ["365E3B", "A3B18A"]
        case .sand: ["F1E7D0", "D8C3A5"]
        case .graphiteGrid: ["252A34", "434B57"]
        case .roseDots: ["862D55", "D9839D"]
        }
    }
    public var texture: Bool { [.linen, .blueprint, .sand, .graphiteGrid, .roseDots].contains(self) }
    public var usesGridTexture: Bool { self == .blueprint || self == .graphiteGrid }
    public var usesDiagonalDotTexture: Bool { self == .roseDots }
}

public enum DeviceFrame: String, Codable, Sendable, CaseIterable, Identifiable {
    case none, window, mac, phone
    public var id: Self { self }
    public var title: String {
        switch self { case .none: "None"; case .window: "Window"; case .mac: "Mac"; case .phone: "Phone" }
    }
}

public enum ScreenshotAspectRatio: String, Codable, Sendable, CaseIterable, Identifiable {
    case original, square, fourByThree, sixteenByNine

    public var id: Self { self }
    public var title: String {
        switch self {
        case .original: "Original"
        case .square: "1:1"
        case .fourByThree: "4:3"
        case .sixteenByNine: "16:9"
        }
    }

    fileprivate var landscapeValue: CGFloat? {
        switch self {
        case .original: nil
        case .square: 1
        case .fourByThree: 4.0 / 3.0
        case .sixteenByNine: 16.0 / 9.0
        }
    }
}

public struct ScreenshotAppearance: Codable, Equatable, Sendable {
    public var backdrop: BackdropPreset = .linen
    public var padding: Double = 32
    public var cornerRadius: Double = 18
    public var backdropCornerRadius: Double = 28
    public var shadowEnabled = true
    public var shadowBlur: Double = 24
    public var shadowOpacity: Double = 0.28
    public var frame: DeviceFrame = .none
    public var aspectRatio: ScreenshotAspectRatio = .original

    public init(backdrop: BackdropPreset = .linen, padding: Double = 32,
                cornerRadius: Double = 18, backdropCornerRadius: Double = 28, shadowEnabled: Bool = true,
                shadowBlur: Double = 24, shadowOpacity: Double = 0.28,
                frame: DeviceFrame = .none,
                aspectRatio: ScreenshotAspectRatio = .original) {
        self.backdrop = backdrop
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.backdropCornerRadius = backdropCornerRadius
        self.shadowEnabled = shadowEnabled
        self.shadowBlur = shadowBlur
        self.shadowOpacity = shadowOpacity
        self.frame = frame
        self.aspectRatio = aspectRatio
    }

    private enum CodingKeys: String, CodingKey {
        case backdrop, padding, cornerRadius, backdropCornerRadius, shadowEnabled, shadowBlur, shadowOpacity, frame, aspectRatio
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        backdrop = try values.decodeIfPresent(BackdropPreset.self, forKey: .backdrop) ?? .linen
        padding = try values.decodeIfPresent(Double.self, forKey: .padding) ?? 32
        cornerRadius = try values.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? 18
        backdropCornerRadius = try values.decodeIfPresent(Double.self, forKey: .backdropCornerRadius) ?? 28
        shadowEnabled = try values.decodeIfPresent(Bool.self, forKey: .shadowEnabled) ?? true
        shadowBlur = try values.decodeIfPresent(Double.self, forKey: .shadowBlur) ?? 24
        shadowOpacity = try values.decodeIfPresent(Double.self, forKey: .shadowOpacity) ?? 0.28
        frame = try values.decodeIfPresent(DeviceFrame.self, forKey: .frame) ?? .none
        aspectRatio = try values.decodeIfPresent(ScreenshotAspectRatio.self, forKey: .aspectRatio) ?? .original
    }

    public static let defaults = ScreenshotAppearance()

    public func outputSize(for imageSize: CGSize) -> CGSize {
        let composition = compositionSize(for: imageSize)
        guard let landscapeRatio = aspectRatio.landscapeValue,
              imageSize.width > 0, imageSize.height > 0, composition.height > 0 else {
            return composition
        }
        let targetRatio = imageSize.width >= imageSize.height ? landscapeRatio : 1 / landscapeRatio
        if composition.width / composition.height < targetRatio {
            return CGSize(width: composition.height * targetRatio, height: composition.height)
        }
        return CGSize(width: composition.width, height: composition.width / targetRatio)
    }

    public func compositionSize(for imageSize: CGSize) -> CGSize {
        let inset = max(0, padding)
        let frameInset: CGFloat = frame == .phone ? 22 : frame == .mac ? 14 : frame == .window ? 2 : 0
        let topBar: CGFloat = frame == .phone ? 42 : frame == .mac ? 28 : frame == .window ? 38 : 0
        let totalInset = inset + frameInset
        return CGSize(width: imageSize.width + 2 * totalInset,
                      height: imageSize.height + 2 * totalInset + topBar)
    }
}
