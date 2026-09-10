import SwiftUI

enum SplitFraction {
    static func constrained(_ fraction: CGFloat, minPrimary: CGFloat?, minSecondary: CGFloat?) -> CGFloat {
        min(1 - (minSecondary ?? 0), max(minPrimary ?? 0, fraction))
    }

    static func externallyUpdated(_ fraction: CGFloat, current: CGFloat, minPrimary: CGFloat?, minSecondary: CGFloat?) -> CGFloat? {
        let constrained = constrained(fraction, minPrimary: minPrimary, minSecondary: minSecondary)
        return constrained == current ? nil : constrained
    }
}

enum SplitTransition {
    static func splitterSide(current: SplitSide?, previous: SplitSide?) -> SplitSide {
        current ?? previous ?? .secondary
    }

    static func edge(for side: SplitSide, layout: SplitLayout) -> Edge {
        switch layout {
        case .horizontal:
            side.isPrimary ? .leading : .trailing
        case .vertical:
            side.isPrimary ? .top : .bottom
        }
    }
}
