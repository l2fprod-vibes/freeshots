import SwiftUI

enum KitIcon {
    case viewfinder, area, window, display
    case select, arrow, shape, text, pen, redact
    case copy, save, drag

    var symbol: String {
        switch self {
        case .viewfinder: "viewfinder"
        case .area: "rectangle.dashed"
        case .window: "macwindow"
        case .display: "display"
        case .select: "cursorarrow"
        case .arrow: "arrow.up.right"
        case .shape: "rectangle"
        case .text: "textformat"
        case .pen: "pencil.tip"
        case .redact: "eye.slash"
        case .copy: "doc.on.doc"
        case .save: "square.and.arrow.down"
        case .drag: "arrow.up.left.and.arrow.down.right"
        }
    }
}

struct KitIconView: View {
    let icon: KitIcon
    var size: CGFloat = 14

    var body: some View {
        Image(systemName: icon.symbol)
            .font(.system(size: size, weight: .regular))
            .frame(width: size + 4, height: size + 4)
            .accessibilityHidden(true)
    }
}
