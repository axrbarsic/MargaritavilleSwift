import Foundation

enum AppStorageDirectory {
    private nonisolated(unsafe) static var applicationSupportOverride: URL?

    static func configureApplicationSupportOverride(_ directory: URL?) {
        applicationSupportOverride = directory
    }

    static func applicationSupportSubdirectory(
        fileManager: FileManager = .default
    ) -> URL {
        if let applicationSupportOverride {
            try? fileManager.createDirectory(at: applicationSupportOverride, withIntermediateDirectories: true)
            return applicationSupportOverride
        }

        let supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = supportDirectory.appendingPathComponent(
            AppIdentity.applicationSupportDirectoryName,
            isDirectory: true
        )
        migrateLegacyDirectoriesIfNeeded(
            supportDirectory: supportDirectory,
            destinationDirectory: directory,
            fileManager: fileManager
        )
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func migrateLegacyDirectoriesIfNeeded(
        supportDirectory: URL,
        destinationDirectory: URL,
        fileManager: FileManager
    ) {
        guard !fileManager.fileExists(atPath: destinationDirectory.path) else { return }
        for legacyName in AppIdentity.legacyApplicationSupportDirectoryNames {
            let legacyDirectory = supportDirectory.appendingPathComponent(legacyName, isDirectory: true)
            guard fileManager.fileExists(atPath: legacyDirectory.path) else { continue }
            try? fileManager.copyItem(at: legacyDirectory, to: destinationDirectory)
            return
        }
    }
}
