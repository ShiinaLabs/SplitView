import SwiftUI

enum SplitFraction {
    static func constrained(_ fraction: CGFloat, minPrimary: CGFloat?, minSecondary: CGFloat?) -> CGFloat {
        min(1 - (minSecondary ?? 0), max(minPrimary ?? 0, fraction))
    }
}

enum SplitTransition {
    static func edge(for side: SplitSide, layout: SplitLayout) -> Edge {
        switch layout {
        case .horizontal:
            side.isPrimary ? .leading : .trailing
        case .vertical:
            side.isPrimary ? .top : .bottom
        }
    }
}
