import Foundation
import XCTest

final class ObservationTests: XCTestCase {
    func testNoDeprecatedOnChangeOverloadsRemain() throws {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceDirectories = [
            packageRoot.appendingPathComponent("Sources/SplitView"),
            packageRoot.appendingPathComponent("Demo/SplitDemo")
        ]

        for directoryURL in sourceDirectories {
            guard let enumerator = FileManager.default.enumerator(
                at: directoryURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else {
                XCTFail("Could not enumerate source directory \(directoryURL.path)")
                continue
            }
            for case let fileURL as URL in enumerator {
                guard fileURL.pathExtension == "swift" else { continue }
                let source = try String(contentsOf: fileURL, encoding: .utf8)
                XCTAssertFalse(
                    source.contains(".onChange(of:"),
                    "Deprecated onChange overload remains in \(fileURL.path)"
                )
            }
        }

        let readmeURL = packageRoot.appendingPathComponent("README.md")
        let readme = try String(contentsOf: readmeURL, encoding: .utf8)
        XCTAssertFalse(
            readme.contains(".onChange(of:"),
            "Deprecated onChange overload remains in \(readmeURL.path)"
        )
    }
}
