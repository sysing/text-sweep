import Foundation
import ZIPFoundation

public final class EPUBRebuilder: EPUBRebuilding {
    public init() {}

    public func rebuild(package: EPUBPackage, outputURL: URL) throws {
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        let archive = try Archive(url: outputURL, accessMode: .create)

        let mimetypeURL = package.workDirectory.appendingPathComponent("mimetype")
        if FileManager.default.fileExists(atPath: mimetypeURL.path) {
            try archive.addEntry(
                with: "mimetype",
                relativeTo: package.workDirectory,
                compressionMethod: .none
            )
        }

        try addAllFiles(in: package.workDirectory, relativeTo: package.workDirectory, archive: archive, skip: Set(["mimetype"]))
    }

    private func addAllFiles(in directory: URL, relativeTo baseDir: URL, archive: Archive, skip: Set<String>) throws {
        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )

        let resolvedBase = baseDir.resolvingSymlinksInPath().path + "/"

        for url in contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let relativePath = url.resolvingSymlinksInPath().path.replacingOccurrences(of: resolvedBase, with: "")

            if skip.contains(relativePath) { continue }

            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else { continue }

            if isDirectory.boolValue {
                try addAllFiles(in: url, relativeTo: baseDir, archive: archive, skip: [])
            } else {
                try archive.addEntry(
                    with: relativePath,
                    relativeTo: baseDir,
                    compressionMethod: .deflate
                )
            }
        }
    }
}
