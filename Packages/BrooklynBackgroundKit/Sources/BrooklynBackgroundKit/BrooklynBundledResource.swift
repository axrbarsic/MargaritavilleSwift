import Foundation

enum BrooklynBundledResource {
    static func url(named name: String, extension fileExtension: String) throws -> URL {
        guard let url = Bundle.module.url(forResource: name, withExtension: fileExtension) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return url
    }

    static func data(named name: String, extension fileExtension: String) throws -> Data {
        try Data(
            contentsOf: url(named: name, extension: fileExtension),
            options: .mappedIfSafe
        )
    }
}
