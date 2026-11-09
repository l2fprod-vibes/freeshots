import AppKit
import SwiftUI

struct AboutFreeshotsView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown version"
    }

    private var badge: NSImage? {
        guard let url = Bundle.main.url(forResource: "made-with-ai-blue-green", withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 68, height: 68)
                .accessibilityHidden(true)

            Text("Freeshots")
                .font(.system(size: 22, weight: .semibold))
            Text("Version \(version)")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            if let badge {
                Image(nsImage: badge)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 116, height: 130)
                    .accessibilityLabel("Made with AI badge")
                    .padding(.top, 4)
            }

            VStack(spacing: 3) {
                Text("AI Badge")
                    .font(.system(size: 12, weight: .medium))
                Text("aibadge.org · CC0 1.0")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("About Freeshots")
    }
}
