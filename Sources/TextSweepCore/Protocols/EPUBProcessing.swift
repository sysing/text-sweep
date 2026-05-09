import Foundation

public protocol EPUBExtracting {
    func extract(from url: URL) throws -> EPUBPackage
}

public protocol EPUBRebuilding {
    func rebuild(package: EPUBPackage, outputURL: URL) throws
}
