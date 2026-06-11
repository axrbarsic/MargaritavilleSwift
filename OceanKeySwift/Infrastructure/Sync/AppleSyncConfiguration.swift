import Foundation

enum AppleSyncConfiguration {
    static let containerIdentifier = "iCloud.com.alex.margaritaville.swift"

    static var defaultSyncMode: SwiftDataWorkSessionRepository.SyncMode {
        .localOnly
    }

    static var cloudKitSyncMode: SwiftDataWorkSessionRepository.SyncMode {
        .privateCloudKit(containerIdentifier: containerIdentifier)
    }

    static func canUsePrivateCloudKitAtRuntime() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}
