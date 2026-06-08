import Foundation

enum AppleSyncConfiguration {
    static let containerIdentifier = "iCloud.com.alex.oceankey.swift"

    static var defaultSyncMode: SwiftDataWorkSessionRepository.SyncMode {
        .privateCloudKit(containerIdentifier: containerIdentifier)
    }
}
