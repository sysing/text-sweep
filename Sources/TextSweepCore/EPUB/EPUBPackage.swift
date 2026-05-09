import Foundation

public struct EPUBPackage {
    public let sourceURL: URL
    public let workDirectory: URL
    public let opfPath: String
    public let metadata: EPUBMetadata
    public let spine: [SpineItem]
    public let manifest: [ManifestItem]

    public init(
        sourceURL: URL,
        workDirectory: URL,
        opfPath: String,
        metadata: EPUBMetadata,
        spine: [SpineItem],
        manifest: [ManifestItem]
    ) {
        self.sourceURL = sourceURL
        self.workDirectory = workDirectory
        self.opfPath = opfPath
        self.metadata = metadata
        self.spine = spine
        self.manifest = manifest
    }
}

public struct SpineItem: Equatable {
    public let id: String
    public let href: String

    public init(id: String, href: String) {
        self.id = id
        self.href = href
    }
}

public struct ManifestItem: Equatable {
    public let id: String
    public let href: String
    public let mediaType: String

    public init(id: String, href: String, mediaType: String) {
        self.id = id
        self.href = href
        self.mediaType = mediaType
    }
}

public struct EPUBMetadata: Equatable {
    public let title: String
    public let identifier: String

    public init(title: String, identifier: String) {
        self.title = title
        self.identifier = identifier
    }
}
