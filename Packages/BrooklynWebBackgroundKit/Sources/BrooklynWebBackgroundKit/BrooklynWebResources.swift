import Foundation

enum BrooklynWebResources {
    enum ResourceError: Error {
        case missingDistribution
        case missingEntryPoint
    }

    static func distributionDirectory() throws -> URL {
        guard let directory = Bundle.module.url(
            forResource: "WebDist",
            withExtension: nil
        ) else {
            throw ResourceError.missingDistribution
        }
        return directory.resolvingSymlinksInPath().standardizedFileURL
    }

    static func entryPoint() throws -> (index: URL, root: URL) {
        let root = try distributionDirectory()
        let index = root.appendingPathComponent("index.html", isDirectory: false)
        guard FileManager.default.fileExists(atPath: index.path) else {
            throw ResourceError.missingEntryPoint
        }
        return (index, root)
    }
}
