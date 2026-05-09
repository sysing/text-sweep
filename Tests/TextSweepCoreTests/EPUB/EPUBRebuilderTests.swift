import XCTest
import ZIPFoundation
@testable import TextSweepCore

final class EPUBRebuilderTests: XCTestCase {
    func testRebuildCreatesValidEPUB() throws {
        let epubURL = try EPUBFixtureBuilder.makeMinimal()
        let extractor = EPUBExtractor()
        let package = try extractor.extract(from: epubURL)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("rebuilt_\(UUID().uuidString).epub")

        let rebuilder = EPUBRebuilder()
        try rebuilder.rebuild(package: package, outputURL: outputURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        // Verify output is a valid ZIP/EPUB
        let rebuiltArchive = try Archive(url: outputURL, accessMode: .read)
        let entryPaths = Set(rebuiltArchive.map(\.path))
        XCTAssertTrue(entryPaths.contains("mimetype"))
        XCTAssertTrue(entryPaths.contains("META-INF/container.xml"))
        XCTAssertTrue(entryPaths.contains("OEBPS/content.opf"))
        XCTAssertTrue(entryPaths.contains("OEBPS/chapter1.xhtml"))
    }

    func testMimetypeIsFirstEntry() throws {
        let epubURL = try EPUBFixtureBuilder.makeMinimal()
        let extractor = EPUBExtractor()
        let package = try extractor.extract(from: epubURL)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("mimetype_test_\(UUID().uuidString).epub")
        defer { try? FileManager.default.removeItem(at: outputURL) }

        let rebuilder = EPUBRebuilder()
        try rebuilder.rebuild(package: package, outputURL: outputURL)

        let archive = try Archive(url: outputURL, accessMode: .read)
        let entries = Array(archive)
        XCTAssertFalse(entries.isEmpty)
        XCTAssertEqual(entries[0].path, "mimetype")
    }

    func testRoundtripPreservesContent() throws {
        let originalBody = "<p>The quick brown fox jumps.</p>"
        let epubURL = try EPUBFixtureBuilder.makeMinimal(bodyHTML: originalBody)
        let extractor = EPUBExtractor()
        let package = try extractor.extract(from: epubURL)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("roundtrip_\(UUID().uuidString).epub")
        defer { try? FileManager.default.removeItem(at: outputURL) }

        let rebuilder = EPUBRebuilder()
        try rebuilder.rebuild(package: package, outputURL: outputURL)

        // Extract the rebuilt EPUB and verify content
        let rebuiltPackage = try extractor.extract(from: outputURL)
        let chapterPath = rebuiltPackage.workDirectory
            .appendingPathComponent("OEBPS/chapter1.xhtml")
        let content = try String(contentsOf: chapterPath, encoding: .utf8)
        XCTAssertTrue(content.contains("The quick brown fox jumps"))
    }

    func testRebuildMultiChapterEPUB() throws {
        let bodies = ["<p>First chapter.</p>", "<p>Second chapter.</p>"]
        let epubURL = try EPUBFixtureBuilder.makeMultiChapter(chapterBodies: bodies)
        let extractor = EPUBExtractor()
        let package = try extractor.extract(from: epubURL)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("multi_rebuild_\(UUID().uuidString).epub")
        defer { try? FileManager.default.removeItem(at: outputURL) }

        let rebuilder = EPUBRebuilder()
        try rebuilder.rebuild(package: package, outputURL: outputURL)

        let rebuiltPackage = try extractor.extract(from: outputURL)
        XCTAssertEqual(rebuiltPackage.spine.count, 2)
    }
}
