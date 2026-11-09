import SwiftUI

struct TextAnalysisOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            GeometryReader { geometry in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let phase = reduceMotion ? 0.5 : time.truncatingRemainder(dividingBy: 2) / 2
                let rotation = reduceMotion ? 0 : time * 150

                ZStack {
                    Color.black.opacity(0.58)

                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, .cyan.opacity(0.18), .cyan.opacity(0.72), .white, .cyan.opacity(0.72), .clear],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(height: 58)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .offset(y: max(0, geometry.size.height - 58) * phase)
                        .shadow(color: .cyan.opacity(0.72), radius: 18)

                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(.white.opacity(0.18), lineWidth: 3)
                            Circle()
                                .trim(from: 0.06, to: 0.78)
                                .stroke(AngularGradient(colors: [.cyan.opacity(0.12), .cyan, .white], center: .center),
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(rotation))
                            Image(systemName: "text.viewfinder")
                                .font(.system(size: 21, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 56, height: 56)

                        Text("Analyzing Screenshot")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Looking for text on this Mac")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.76))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(.ultraThinMaterial.opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.16), lineWidth: 1))
                    .shadow(color: .black.opacity(0.32), radius: 22, y: 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Analyzing screenshot for text")
    }
}
