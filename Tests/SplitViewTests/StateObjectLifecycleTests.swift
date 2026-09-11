#if os(macOS)

import AppKit
import SwiftUI
import XCTest
@testable import SplitView

@MainActor
final class StateObjectLifecycleTests: XCTestCase {
    func testCallerOwnedFractionIsNotRetainedByStateObjectAcrossRebuild() {
        let model = FractionRebuildModel()
        let hostingView = NSHostingView(rootView: FractionRebuildHarness(model: model))
        hostingView.frame = NSRect(x: 0, y: 0, width: 320, height: 200)
        hostingView.layoutSubtreeIfNeeded()

        model.replaceHolder()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        hostingView.layoutSubtreeIfNeeded()

        XCTAssertNil(model.previousHolder)
    }
}

@MainActor
private final class FractionRebuildModel: ObservableObject {
    @Published private(set) var generation = 0
    var currentHolder = FractionHolder(0.25)
    weak var previousHolder: FractionHolder?

    func replaceHolder() {
        previousHolder = currentHolder
        currentHolder = FractionHolder(0.75)
        generation += 1
    }
}

private struct FractionRebuildHarness: View {
    @ObservedObject var model: FractionRebuildModel

    var body: some View {
        HSplit(left: { Color.red }, right: { Color.blue })
            .constraints(minPFraction: 0.2, minSFraction: 0.2)
            .onDrag { _ in }
            .styling(visibleThickness: 4)
            .splitter { Splitter() }
            .fraction(model.currentHolder)
            .frame(width: 320, height: 200)
    }
}

#endif
