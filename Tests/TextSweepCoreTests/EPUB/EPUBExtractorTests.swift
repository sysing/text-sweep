import XCTest
import ZIPFoundation
@testable import TextSweepCore

final class EPUBExtractorTests: XCTestCase {
    func testExtractsMinimalEPUB() throws {
        let epubURL = try EPUBFixtureBuilder.makeMinimal()
        let extractor = EPUBExtractor()
        let package = try extractor.extract(from: epubURL)

        XCTAssertEqual(package.metadata.title, "Test Book")
        XCTAssertEqual(package.spine.count, 1)
        XCTAssertEqual(package.spine.first?.id, "chapter1")
        XCTAssertEqual(package.spine.first?.href, "chapter1.xhtml")
        XCTAssertEqual(package.manifest.count, 1)
        XCTAssertEqual(package.manifest.first?.mediaType, "application/xhtml+xml")
    }

    func testExtractsMultiChapterEPUB() throws {
        let bodies = [
            "<p>Chapter one text.</p>",
            "<p>Chapter two text.</p>",
            "<p>Chapter three text.</p>",
        ]
        let epubURL = try EPUBFixtureBuilder.makeMultiChapter(chapterBodies: bodies)
        let extractor = EPUBExtractor()
        let package = try extractor.extract(from: epubURL)

        XCTAssertEqual(package.spine.count, 3)
        XCTAssertEqual(package.manifest.count, 3)
        XCTAssertEqual(package.spine[0].id, "chapter1")
        XCTAssertEqual(package.spine[1].id, "chapter2")
        XCTAssertEqual(package.spine[2].id, "chapter3")
    }

    func testExtractsWorkDirectoryWithContent() throws {
        let epubURL = try EPUBFixtureBuilder.makeMinimal()
        let extractor = EPUBExtractor()
        let package = try extractor.extract(from: epubURL)

        let chapterPath = package.workDirectory
            .appendingPathComponent("OEBPS/chapter1.xhtml")
        XCTAssertTrue(FileManager.default.fileExists(atPath: chapterPath.path))

        let content = try String(contentsOf: chapterPath, encoding: .utf8)
        XCTAssertTrue(content.contains("The quick brown fox"))
    }

    func testOPFContentExists() throws {
        let epubURL = try EPUBFixtureBuilder.makeMinimal()
        let extractor = EPUBExtractor()
        let package = try extractor.extract(from: epubURL)

        let opfPath = package.workDirectory.appendingPathComponent(package.opfPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: opfPath.path))
    }

    func testThrowsOnNonEPUBFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let fakeURL = tempDir.appendingPathComponent("not-an-epub.txt")
        try "not an epub".write(to: fakeURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fakeURL) }

        let extractor = EPUBExtractor()
        XCTAssertThrowsError(try extractor.extract(from: fakeURL))
    }

    func testIdentifierIsParsed() throws {
        let epubURL = try EPUBFixtureBuilder.makeMinimal()
        let extractor = EPUBExtractor()
        let package = try extractor.extract(from: epubURL)

        XCTAssertEqual(package.metadata.identifier, "urn:uuid:00000000-0000-0000-0000-000000000001")
    }

    func testSpineOrderMatchesManifest() throws {
        let bodies = ["<p>A</p>", "<p>B</p>", "<p>C</p>"]
        let epubURL = try EPUBFixtureBuilder.makeMultiChapter(chapterBodies: bodies)
        let extractor = EPUBExtractor()
        let package = try extractor.extract(from: epubURL)

        for spineItem in package.spine {
            let matchingManifest = package.manifest.first { $0.id == spineItem.id }
            XCTAssertNotNil(matchingManifest)
            XCTAssertEqual(matchingManifest?.href, spineItem.href)
        }
    }
}
