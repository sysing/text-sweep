import Foundation
import ZIPFoundation

enum EPUBFixtureBuilder {
    static func makeMinimal(
        title: String = "Test Book",
        bodyHTML: String = "<p>The quick brown fox jumps over the lazy dog.</p>"
    ) throws -> URL {
        let chapters: [String] = bodyHTML.isEmpty ? ["<p>Placeholder text.</p>"] : [bodyHTML]
        let epubDir = try writeEPUBStructure(title: title, chapters: chapters, chapterBodies: chapters)
        return try zipEPUB(from: epubDir)
    }

    static func makeMultiChapter(
        title: String = "Multi Chapter",
        chapterBodies: [String]
    ) throws -> URL {
        let chapters = (1...chapterBodies.count).map { "Chapter \($0)" }
        let epubDir = try writeEPUBStructure(title: title, chapters: chapters, chapterBodies: chapterBodies)
        return try zipEPUB(from: epubDir)
    }

    static func makeWithInlineFormatting(
        title: String = "Formatted Text",
        bodyHTML: String
    ) throws -> URL {
        let epubDir = try writeEPUBStructure(
            title: title,
            chapters: ["Chapter 1"],
            chapterBodies: [bodyHTML]
        )
        return try zipEPUB(from: epubDir)
    }

    private static func writeEPUBStructure(
        title: String,
        chapters: [String],
        chapterBodies: [String]
    ) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("epub_fixture_" + UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        try writeMimetype(in: dir)
        try writeContainer(in: dir)
        try writeOPF(title: title, chapters: chapters, bodyPaths: chapterBodies.indices.map { "chapter\($0 + 1).xhtml" }, in: dir)
        try writeChapters(bodies: chapterBodies, in: dir)

        return dir
    }

    private static func writeMimetype(in dir: URL) throws {
        let data = "application/epub+zip".data(using: .utf8)!
        try data.write(to: dir.appendingPathComponent("mimetype"))
    }

    private static func writeContainer(in dir: URL) throws {
        let containerDir = dir.appendingPathComponent("META-INF")
        try FileManager.default.createDirectory(at: containerDir, withIntermediateDirectories: true)

        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
          <rootfiles>
            <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
          </rootfiles>
        </container>
        """
        try xml.write(to: containerDir.appendingPathComponent("container.xml"), atomically: true, encoding: .utf8)
    }

    private static func writeOPF(title: String, chapters: [String], bodyPaths: [String], in dir: URL) throws {
        let oebpsDir = dir.appendingPathComponent("OEBPS")
        try FileManager.default.createDirectory(at: oebpsDir, withIntermediateDirectories: true)

        var manifestItems = ""
        var spineItems = ""
        for i in 0..<bodyPaths.count {
            let id = "chapter\(i + 1)"
            manifestItems += """
                <item id="\(id)" href="\(bodyPaths[i])" media-type="application/xhtml+xml"/>
            """
            spineItems += """
                <itemref idref="\(id)"/>
            """
        }

        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <package version="3.0" unique-identifier="book-id" xmlns="http://www.idpf.org/2007/opf">
          <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
            <dc:title>\(title)</dc:title>
            <dc:identifier id="book-id">urn:uuid:00000000-0000-0000-0000-000000000001</dc:identifier>
            <meta property="dcterms:modified">2024-01-01T00:00:00Z</meta>
          </metadata>
          <manifest>
        \(manifestItems)
          </manifest>
          <spine>
        \(spineItems)
          </spine>
        </package>
        """
        try xml.write(to: oebpsDir.appendingPathComponent("content.opf"), atomically: true, encoding: .utf8)
    }

    private static func writeChapters(bodies: [String], in dir: URL) throws {
        let oebpsDir = dir.appendingPathComponent("OEBPS")
        for (i, body) in bodies.enumerated() {
            let xhtml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE html>
            <html xmlns="http://www.w3.org/1999/xhtml">
            <head><title>Chapter \(i + 1)</title></head>
            <body>\(body)</body>
            </html>
            """
            try xhtml.write(to: oebpsDir.appendingPathComponent("chapter\(i + 1).xhtml"), atomically: true, encoding: .utf8)
        }
    }

    private static func zipEPUB(from dir: URL) throws -> URL {
        let epubURL = dir.appendingPathComponent("output.epub")
        let archive = try Archive(url: epubURL, accessMode: .create)

        try archive.addEntry(with: "mimetype", relativeTo: dir, compressionMethod: .none)

        try archive.addEntry(with: "META-INF/container.xml", relativeTo: dir)

        try archive.addEntry(with: "OEBPS/content.opf", relativeTo: dir)

        let opfDir = dir.appendingPathComponent("OEBPS")
        let chapterFiles = try FileManager.default.contentsOfDirectory(
            at: opfDir,
            includingPropertiesForKeys: nil
        ).filter { $0.lastPathComponent.hasPrefix("chapter") && $0.pathExtension == "xhtml" }

        for chapterFile in chapterFiles.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            try archive.addEntry(
                with: "OEBPS/\(chapterFile.lastPathComponent)",
                relativeTo: dir
            )
        }

        return epubURL
    }
}
