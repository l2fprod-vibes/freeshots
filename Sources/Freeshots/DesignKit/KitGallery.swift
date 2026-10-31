import SwiftUI

struct KitGallery: View {
    static let enabled = ProcessInfo.processInfo.environment["APP_KIT_GALLERY"] == "1"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Freeshots Parts")
                    .kitType(.title)
                    .foregroundStyle(Ink.text)

                stateGrid(title: "Primary action") { state in
                    Button("Copy") {}
                        .buttonStyle(.kit(.primary))
                        .disabled(state == .disabled)
                }

                stateGrid(title: "Secondary action") { state in
                    Button("Save…") {}
                        .buttonStyle(.kit(.secondary))
                        .disabled(state == .disabled)
                }

                stateGrid(title: "Markup tool") { state in
                    Button {} label: { KitIconView(icon: .arrow) }
                        .buttonStyle(KitToolButtonStyle(selected: state == .selected))
                        .help("Arrow (A)")
                        .accessibilityLabel("Arrow")
                        .disabled(state == .disabled)
                }

                dragHandlePreview
            }
            .padding(24)
        }
        .background(Ink.canvas)
    }

    private func stateGrid<Part: View>(title: String, @ViewBuilder part: @escaping (PartState) -> Part) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .kitType(.labelStrong)
                .foregroundStyle(Ink.text)
            HStack(alignment: .top, spacing: 14) {
                ForEach(PartState.allCases, id: \.self) { state in
                    VStack(spacing: 6) {
                        part(state)
                            .environment(\.forcedPartState, state)
                        Text(state.rawValue)
                            .kitType(.meta)
                            .foregroundStyle(Ink.muted)
                    }
                }
            }
        }
    }

    private var dragHandlePreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Drag to Save")
                .kitType(.labelStrong)
                .foregroundStyle(Ink.text)
            HStack(spacing: 8) {
                KitIconView(icon: .drag)
                Text("Drag to Save")
            }
            .kitType(.labelStrong)
            .foregroundStyle(Ink.text)
            .padding(.horizontal, 12)
            .frame(height: KitMetric.actionHeight)
            .background(Ink.surface, in: RoundedRectangle(cornerRadius: KitMetric.controlRadius))
        }
    }
}
