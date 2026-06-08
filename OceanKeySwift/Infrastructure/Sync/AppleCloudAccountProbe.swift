import CloudKit
import Foundation

enum AppleCloudAccountStatus: Equatable, Sendable {
    case unknown
    case available
    case noAccount
    case restricted
    case temporarilyUnavailable
    case couldNotDetermine

    init(_ status: CKAccountStatus) {
        switch status {
        case .available:
            self = .available
        case .noAccount:
            self = .noAccount
        case .restricted:
            self = .restricted
        case .temporarilyUnavailable:
            self = .temporarilyUnavailable
        case .couldNotDetermine:
            self = .couldNotDetermine
        @unknown default:
            self = .couldNotDetermine
        }
    }
}

enum AppleCloudAccountProbe {
    static func status(containerIdentifier: String) async -> AppleCloudAccountStatus {
        await withCheckedContinuation { continuation in
            CKContainer(identifier: containerIdentifier).accountStatus { status, error in
                if error != nil {
                    continuation.resume(returning: .couldNotDetermine)
                } else {
                    continuation.resume(returning: AppleCloudAccountStatus(status))
                }
            }
        }
    }
}
