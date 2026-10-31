import Foundation

public enum BackdropPreset: String, CaseIterable, Codable, Sendable, Identifiable {
    case transparent, paper, ocean, violet, sunset, mint, graphite, linen, blueprint
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
        }
    }
    public var texture: Bool { self == .linen || self == .blueprint }
}

public enum DeviceFrame: String, Codable, Sendable, CaseIterable, Identifiable {
    case none, mac, phone
    public var id: Self { self }
    public var title: String {
        switch self { case .none: "None"; case .mac: "Mac"; case .phone: "Phone" }
    }
}

public struct ScreenshotAppearance: Codable, Equatable, Sendable {
    public var backdrop: BackdropPreset = .transparent
    public var padding: Double = 64
    public var cornerRadius: Double = 18
    public var shadowEnabled = true
    public var shadowBlur: Double = 24
    public var shadowOpacity: Double = 0.28
    public var frame: DeviceFrame = .none

    public init(backdrop: BackdropPreset = .transparent, padding: Double = 64,
                cornerRadius: Double = 18, shadowEnabled: Bool = true,
                shadowBlur: Double = 24, shadowOpacity: Double = 0.28,
                frame: DeviceFrame = .none) {
        self.backdrop = backdrop
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowEnabled = shadowEnabled
        self.shadowBlur = shadowBlur
        self.shadowOpacity = shadowOpacity
        self.frame = frame
    }

    public static let defaults = ScreenshotAppearance()

    public func outputSize(for imageSize: CGSize) -> CGSize {
        let inset = max(0, padding)
        let shadowInset = shadowEnabled ? ceil(max(0, shadowBlur) * 2) : 0
        let frameInset: CGFloat = frame == .phone ? 22 : frame == .mac ? 14 : 0
        let topBar: CGFloat = frame == .phone ? 42 : frame == .mac ? 28 : 0
        let totalInset = inset + shadowInset + frameInset
        return CGSize(width: imageSize.width + 2 * totalInset,
                      height: imageSize.height + 2 * totalInset + topBar)
    }
}
