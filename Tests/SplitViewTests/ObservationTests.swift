import Foundation
import XCTest

final class ObservationTests: XCTestCase {
    func testNoDeprecatedOnChangeOverloadsRemain() throws {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let paths = [
            "Sources/SplitView/Split.swift",
            "Sources/SplitView/Splitter.swift",
            "Demo/SplitDemo/DemoSplitter.swift",
            "README.md"
        ]

        for relativePath in paths {
            let fileURL = packageRoot.appendingPathComponent(relativePath)
            let source = try String(contentsOf: fileURL, encoding: .utf8)
            XCTAssertFalse(
                source.contains(".onChange(of:"),
                "Deprecated onChange overload remains in \(relativePath)"
            )
        }
    }
}
