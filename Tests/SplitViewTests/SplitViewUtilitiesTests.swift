import XCTest
import SwiftUI
@testable import SplitView

final class SplitViewUtilitiesTests: XCTestCase {
    func testConstrainedClampsToPrimaryMinimum() {
        XCTAssertEqual(
            SplitFraction.constrained(0.1, minPrimary: 0.2, minSecondary: 0.3),
            0.2
        )
    }

    func testConstrainedClampsToSecondaryMinimum() {
        XCTAssertEqual(
            SplitFraction.constrained(0.9, minPrimary: 0.2, minSecondary: 0.3),
            0.7
        )
    }

    func testEdgeMapsSidesForHorizontalLayout() {
        XCTAssertEqual(SplitTransition.edge(for: .primary, layout: .horizontal), .leading)
        XCTAssertEqual(SplitTransition.edge(for: .secondary, layout: .horizontal), .trailing)
    }

    func testEdgeMapsSidesForVerticalLayout() {
        XCTAssertEqual(SplitTransition.edge(for: .primary, layout: .vertical), .top)
        XCTAssertEqual(SplitTransition.edge(for: .secondary, layout: .vertical), .bottom)
    }
}
