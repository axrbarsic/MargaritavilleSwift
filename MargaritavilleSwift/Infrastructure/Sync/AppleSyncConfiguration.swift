import Foundation

enum AppleSyncConfiguration {
    static let containerIdentifier = "iCloud.\(AppIdentity.bundleIdentifier)"

    static var defaultSyncMode: SwiftDataWorkSessionRepository.SyncMode {
        .localOnly
    }

    static var cloudKitSyncMode: SwiftDataWorkSessionRepository.SyncMode {
        .privateCloudKit(containerIdentifier: containerIdentifier)
    }

    static func canUsePrivateCloudKitAtRuntime() -> Bool {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return false
        }
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}
