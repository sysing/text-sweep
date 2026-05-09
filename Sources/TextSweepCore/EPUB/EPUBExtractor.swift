import Foundation
import ZIPFoundation

public final class EPUBExtractor: EPUBExtracting {
    public init() {}

    public func extract(from url: URL) throws -> EPUBPackage {
        let workDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("textsweep_" + UUID().uuidString)
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)

        let archive: Archive
        do {
            archive = try Archive(url: url, accessMode: .read)
        } catch {
            throw ConversionError.notAnEPUB
        }

        var directories: Set<String> = [workDir.path]
        for entry in archive {
            let destination = workDir.appendingPathComponent(entry.path)
            if entry.type == .directory {
                try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
                directories.insert(destination.path)
            } else {
                let parent = destination.deletingLastPathComponent()
                if !directories.contains(parent.path) {
                    try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
                    directories.insert(parent.path)
                }
                _ = try archive.extract(entry, to: destination)
            }
        }

        let containerURL = workDir.appendingPathComponent("META-INF/container.xml")
        guard FileManager.default.fileExists(atPath: containerURL.path) else {
            throw ConversionError.missingContainerXML
        }
        let containerData = try Data(contentsOf: containerURL)
        let opfPath = try EPUBContainerParser.opfPath(from: containerData)

        let opfURL = workDir.appendingPathComponent(opfPath)
        guard FileManager.default.fileExists(atPath: opfURL.path) else {
            throw ConversionError.missingOPF
        }
        let opfData = try Data(contentsOf: opfURL)
        let opfResult = try EPUBOPFParser.parse(data: opfData)

        let spine: [SpineItem] = opfResult.spineIDRefs.compactMap { idref in
            guard let item = opfResult.manifestItems.first(where: { $0.id == idref }) else {
                return nil
            }
            return SpineItem(id: item.id, href: item.href)
        }

        let manifest: [ManifestItem] = opfResult.manifestItems.map {
            ManifestItem(id: $0.id, href: $0.href, mediaType: $0.mediaType)
        }

        let metadata = EPUBMetadata(
            title: opfResult.title ?? "Untitled",
            identifier: opfResult.identifier ?? "unknown"
        )

        return EPUBPackage(
            sourceURL: url,
            workDirectory: workDir,
            opfPath: opfPath,
            metadata: metadata,
            spine: spine,
            manifest: manifest
        )
    }
}

private enum EPUBContainerParser {
    static func opfPath(from data: Data) throws -> String {
        let delegate = ContainerDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse(), let path = delegate.rootfilePath else {
            throw ConversionError.missingOPF
        }
        return path
    }

    private final class ContainerDelegate: NSObject, XMLParserDelegate {
        var rootfilePath: String?

        func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?,
            attributes attributeDict: [String: String] = [:]
        ) {
            if elementName == "rootfile", let path = attributeDict["full-path"] {
                rootfilePath = path
            }
        }
    }
}

private enum EPUBOPFParser {
    struct Result {
        var title: String?
        var identifier: String?
        var manifestItems: [RawManifestItem] = []
        var spineIDRefs: [String] = []
    }

    struct RawManifestItem {
        let id: String
        let href: String
        let mediaType: String
    }

    static func parse(data: Data) throws -> Result {
        let delegate = OPFDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse() else {
            throw ConversionError.invalidHTML("Failed to parse OPF file")
        }
        return delegate.result
    }

    private final class OPFDelegate: NSObject, XMLParserDelegate {
        var result = Result()
        private var currentElement = ""
        private var currentText = ""

        func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?,
            attributes attributeDict: [String: String] = [:]
        ) {
            currentElement = elementName
            currentText = ""

            if elementName == "item" {
                if let id = attributeDict["id"],
                   let href = attributeDict["href"] {
                    let mediaType = attributeDict["media-type"] ?? "application/octet-stream"
                    result.manifestItems.append(
                        RawManifestItem(id: id, href: href, mediaType: mediaType)
                    )
                }
            }

            if elementName == "itemref", let idref = attributeDict["idref"] {
                result.spineIDRefs.append(idref)
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            currentText += string
        }

        func parser(
            _ parser: XMLParser,
            didEndElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?
        ) {
            let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            if currentElement == "dc:title" || currentElement == "title" {
                if result.title == nil { result.title = trimmed }
            }
            if currentElement == "dc:identifier" || currentElement == "identifier" {
                if result.identifier == nil { result.identifier = trimmed }
            }
            currentElement = ""
            currentText = ""
        }
    }
}
