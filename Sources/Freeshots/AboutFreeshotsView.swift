import AppKit
import SwiftUI

struct AboutFreeshotsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pointerPosition = CGPoint(x: 0.5, y: 0.5)
    @State private var isPointerInside = false

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.1"
    }

    private var badge: NSImage? {
        guard let url = Bundle.module.url(forResource: "made-with-ai-blue-green", withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
                    auroraBackground(size: geometry.size, time: timeline.date.timeIntervalSinceReferenceDate)
                }
            }

            VStack(spacing: 16) {
                Spacer(minLength: 8)

                Text("Freeshots")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tracking(-0.6)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 2)

                Text("Version \(version)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.12), in: Capsule())
                    .overlay(Capsule().strokeBorder(.white.opacity(0.16), lineWidth: 1))

                if let badge {
                    Image(nsImage: badge)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 164, height: 184)
                        .shadow(color: Color.cyan.opacity(0.24), radius: 24, y: 8)
                        .accessibilityLabel("Made with AI badge")
                        .padding(.top, 4)
                }

                Spacer(minLength: 8)
            }
            .padding(24)
        }
        .frame(width: 420, height: 470)
        .background(Color(red: 0.035, green: 0.055, blue: 0.15))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("About Freeshots")
        .contentShape(Rectangle())
        .onContinuousHover { phase in
            guard !reduceMotion else { return }
            switch phase {
            case .active(let location):
                let normalized = CGPoint(
                    x: min(max(location.x / 420, 0), 1),
                    y: min(max(location.y / 470, 0), 1)
                )
                withAnimation(.easeOut(duration: 0.32)) {
                    pointerPosition = normalized
                    isPointerInside = true
                }
            case .ended:
                withAnimation(.easeOut(duration: 0.55)) {
                    isPointerInside = false
                    pointerPosition = CGPoint(x: 0.5, y: 0.5)
                }
            }
        }
    }

    private func auroraBackground(size: CGSize, time: TimeInterval) -> some View {
        let phase = time * 0.12
        let slowPhase = time * 0.075
        let pointerX = (pointerPosition.x - 0.5) * size.width
        let pointerY = (pointerPosition.y - 0.5) * size.height
        let pointerInfluence: CGFloat = isPointerInside && !reduceMotion ? 1 : 0
        let driftX = CGFloat(sin(phase))
        let driftY = CGFloat(cos(slowPhase))

        return ZStack {
            LinearGradient(
                colors: [Color(red: 0.02, green: 0.16, blue: 0.34), Color(red: 0.13, green: 0.11, blue: 0.36), Color(red: 0.02, green: 0.31, blue: 0.34)],
                startPoint: UnitPoint(x: 0.5 + driftX * 0.45, y: 0.5 - driftY * 0.45),
                endPoint: UnitPoint(x: 0.5 - driftY * 0.45, y: 0.5 + driftX * 0.45)
            )

            Circle()
                .fill(Color.cyan.opacity(0.48))
                .frame(width: 220, height: 220)
                .blur(radius: 76)
                .offset(
                    x: driftX * 132 + pointerX * 0.16 * pointerInfluence,
                    y: driftY * 106 + pointerY * 0.16 * pointerInfluence
                ) // grid: ok, animated aurora glow and pointer parallax

            Circle()
                .fill(Color.mint.opacity(0.38))
                .frame(width: 240, height: 240)
                .blur(radius: 88)
                .offset(
                    x: -driftY * 116 - pointerX * 0.1 * pointerInfluence,
                    y: -driftX * 120 - pointerY * 0.1 * pointerInfluence
                ) // grid: ok, animated aurora glow and pointer parallax

            RadialGradient(
                colors: [.white.opacity(isPointerInside ? 0.17 : 0), .cyan.opacity(0.035), .clear],
                center: UnitPoint(x: pointerPosition.x, y: pointerPosition.y),
                startRadius: 0,
                endRadius: 230
            )
            .blendMode(.screen)

            LinearGradient(colors: [.black.opacity(0.06), .clear, .black.opacity(0.18)], startPoint: .top, endPoint: .bottom)
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.32), value: pointerPosition)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.32), value: isPointerInside)
        .accessibilityHidden(true)
        .ignoresSafeArea()
    }
}
