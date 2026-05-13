import SwiftUI
import TextSweepCore
import UniformTypeIdentifiers

@MainActor
final class ConversionViewModel: ObservableObject {
    @Published var isDragging = false
    @Published var isConverting = false
    @Published var selectedFilename: String?
    @Published var outputURL: URL?
    @Published var errorMessage: String?
    @Published var config = BionicConfigViewModel()

    @AppStorage("recentFilePaths") private var recentFilePathsJSON: String = "[]"

    private var selectedURL: URL?
    private let extractor: EPUBExtracting = EPUBExtractor()
    private let transformer: BionicTransforming = BionicTransformer()
    private let rebuilder: EPUBRebuilding = EPUBRebuilder()

    private static let epubUTType: UTType = UTType(filenameExtension: "epub")
        ?? UTType("org.idpf.epub-container")
        ?? .data

    var recentFiles: [URL] {
        guard let data = recentFilePathsJSON.data(using: .utf8),
              let paths = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return paths.compactMap { URL(fileURLWithPath: $0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    func selectFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [Self.epubUTType]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        setSelectedFile(url)
        addToRecentFiles(url)
    }

    func openRecentFile(_ url: URL) {
        setSelectedFile(url)
    }

    func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { [weak self] item, _ in
            let url: URL? = {
                if let directURL = item as? URL {
                    return directURL
                }
                if let data = item as? Data,
                   let rawPath = String(data: data, encoding: .utf8),
                   let trimmedURL = URL(string: rawPath.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    return trimmedURL
                }
                return nil
            }()

            guard let url = url, url.pathExtension.lowercased() == "epub" else { return }

            Task { @MainActor in
                self?.setSelectedFile(url.resolvingSymlinksInPath())
                self?.addToRecentFiles(url.resolvingSymlinksInPath())
            }
        }
    }

    func convert() {
        guard let inputURL = selectedURL else { return }

        isConverting = true
        errorMessage = nil
        outputURL = nil

        Task {
            do {
                let package = try extractor.extract(from: inputURL)

                let opfDir = package.opfPath
                    .split(separator: "/").dropLast().joined(separator: "/")

                for spineItem in package.spine {
                    let xhtmlPath = package.workDirectory
                        .appendingPathComponent(opfDir)
                        .appendingPathComponent(spineItem.href)
                    var html = try String(contentsOf: xhtmlPath, encoding: .utf8)
                    html = try self.transformer.transform(html: html, config: self.config.toCoreConfig)
                    try html.write(to: xhtmlPath, atomically: true, encoding: .utf8)
                }

                let documentsDir = FileManager.default.urls(
                    for: .documentDirectory, in: .userDomainMask
                ).first!
                let safeTitle = package.metadata.title
                    .replacingOccurrences(of: "/", with: "-")
                    .replacingOccurrences(of: ":", with: "-")
                    .trimmingCharacters(in: .whitespaces)
                let outputURL = documentsDir
                    .appendingPathComponent(safeTitle + "_bionic")
                    .appendingPathExtension("epub")

                print("Output path: \(outputURL.path)")
                try self.rebuilder.rebuild(package: package, outputURL: outputURL)

                await MainActor.run {
                    self.outputURL = outputURL
                    self.isConverting = false
                    print("Conversion complete: \(outputURL.path)")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isConverting = false
                }
            }
        }
    }

    func openInBooks() {
        guard let url = outputURL else { return }
        NSWorkspace.shared.open(url)
    }

    private func setSelectedFile(_ url: URL) {
        selectedURL = url
        selectedFilename = url.lastPathComponent
        errorMessage = nil
        outputURL = nil
    }

    private func addToRecentFiles(_ url: URL) {
        var files = recentFiles.map(\.path)
        files.removeAll { $0 == url.path }
        files.insert(url.path, at: 0)
        files = Array(files.prefix(10))
        if let data = try? JSONEncoder().encode(files),
           let json = String(data: data, encoding: .utf8) {
            recentFilePathsJSON = json
        }
    }
}
