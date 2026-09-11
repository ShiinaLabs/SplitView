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
        let deprecatedOnChange = try NSRegularExpression(
            pattern: #"\.onChange\(of:[^)]*\)\s*\{\s*[A-Za-z_][A-Za-z0-9_]*\s+in"#,
            options: []
        )

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
                XCTAssertNil(
                    deprecatedOnChange.firstMatch(
                        in: source,
                        options: [],
                        range: NSRange(source.startIndex..<source.endIndex, in: source)
                    ),
                    "Deprecated onChange overload remains in \(fileURL.path)"
                )
            }
        }

        let readmeURL = packageRoot.appendingPathComponent("README.md")
        let readme = try String(contentsOf: readmeURL, encoding: .utf8)
        XCTAssertNil(
            deprecatedOnChange.firstMatch(
                in: readme,
                options: [],
                range: NSRange(readme.startIndex..<readme.endIndex, in: readme)
            ),
            "Deprecated onChange overload remains in \(readmeURL.path)"
        )
    }

    func testSplitKeepsDefaultFractionStateOwnedAndExternalFractionSeparate() throws {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let splitURL = packageRoot.appendingPathComponent("Sources/SplitView/Split.swift")
        let source = try String(contentsOf: splitURL, encoding: .utf8)

        XCTAssertTrue(source.contains("@StateObject private var fraction: FractionHolder"))
        XCTAssertTrue(source.contains("private let explicitFraction: FractionHolder?"))
        XCTAssertTrue(source.contains("SplitFraction.activeHolder"))
        XCTAssertFalse(source.contains("@ObservedObject private var fraction: FractionHolder"))
    }

    func testSplitDoesNotForceHideShowAnimation() throws {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let splitURL = packageRoot.appendingPathComponent("Sources/SplitView/Split.swift")
        let source = try String(contentsOf: splitURL, encoding: .utf8)

        XCTAssertFalse(source.contains(".animation(.default, value: hide.side?.rawValue)"))
    }
}
