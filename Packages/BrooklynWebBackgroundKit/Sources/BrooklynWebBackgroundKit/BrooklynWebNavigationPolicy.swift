import Foundation

public enum BrooklynWebNavigationPolicy {
    public static func allows(
        _ candidateURL: URL?,
        inside distributionDirectory: URL
    ) -> Bool {
        guard let candidateURL, candidateURL.isFileURL else { return false }

        let root = distributionDirectory
            .resolvingSymlinksInPath()
            .standardizedFileURL
        let candidate = candidateURL
            .resolvingSymlinksInPath()
            .standardizedFileURL
        let rootPath = root.path.hasSuffix("/") ? root.path : root.path + "/"

        return candidate.path == root.path || candidate.path.hasPrefix(rootPath)
    }
}
