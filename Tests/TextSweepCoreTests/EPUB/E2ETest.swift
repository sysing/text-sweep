import XCTest
import ZIPFoundation
@testable import TextSweepCore

final class E2ETest: XCTestCase {
    func testFullPipeline() throws {
        let epubURL = try EPUBFixtureBuilder.makeMinimal(bodyHTML: "<p>The quick brown fox.</p>")
        let extractor = EPUBExtractor()
        let transformer = BionicTransformer()
        let rebuilder = EPUBRebuilder()
        let config = BionicConfig(fixationRatio: 0.33, minimumWordLength: 2)

        let package = try extractor.extract(from: epubURL)
        let opfDir = package.opfPath.split(separator: "/").dropLast().joined(separator: "/")

        for spineItem in package.spine {
            let xhtmlPath = package.workDirectory
                .appendingPathComponent(opfDir)
                .appendingPathComponent(spineItem.href)
            let original = try String(contentsOf: xhtmlPath, encoding: .utf8)
            print("=== ORIGINAL (\(spineItem.href)) ===")
            print(original.prefix(200))

            let transformed = try transformer.transform(html: original, config: config)
            print("=== TRANSFORMED (\(spineItem.href)) ===")
            print(transformed.prefix(200))

            try transformed.write(to: xhtmlPath, atomically: true, encoding: .utf8)
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("e2e_test.epub")
        try rebuilder.rebuild(package: package, outputURL: outputURL)

        let rebuiltSize = try Data(contentsOf: outputURL).count
        print("=== REBUILT EPUB: \(rebuiltSize) bytes ===")
        XCTAssertGreaterThan(rebuiltSize, 100, "Rebuilt EPUB is too small, likely empty")

        let rebuiltPackage = try extractor.extract(from: outputURL)
        for spineItem in rebuiltPackage.spine {
            let xhtmlPath = rebuiltPackage.workDirectory
                .appendingPathComponent(opfDir)
                .appendingPathComponent(spineItem.href)
            let content = try String(contentsOf: xhtmlPath, encoding: .utf8)
            print("=== ROUNDTRIP (\(spineItem.href)) ===")
            print(content.prefix(200))
            XCTAssertTrue(content.contains("<b>T</b>he"), "Expected bionic bold tag in output")
        }
    }
}
