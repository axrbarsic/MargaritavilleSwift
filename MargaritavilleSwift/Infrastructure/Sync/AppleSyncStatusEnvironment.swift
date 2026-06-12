import SwiftUI

struct AppleSyncStatus: Equatable, Sendable {
    let requestedMode: SwiftDataWorkSessionRepository.SyncMode
    let activeMode: SwiftDataWorkSessionRepository.SyncMode
    var accountStatus: AppleCloudAccountStatus

    static let localOnly = AppleSyncStatus(
        requestedMode: .localOnly,
        activeMode: .localOnly,
        accountStatus: .unknown
    )

    static func repository(_ repository: SwiftDataWorkSessionRepository) -> AppleSyncStatus {
        AppleSyncStatus(
            requestedMode: repository.syncMode,
            activeMode: repository.activeSyncMode,
            accountStatus: .unknown
        )
    }

    var isCloudRequested: Bool {
        if case .privateCloudKit = requestedMode { return true }
        return false
    }

    var isCloudActive: Bool {
        if case .privateCloudKit = activeMode { return true }
        return false
    }

    var statusLabel: String {
        if isCloudRequested {
            switch accountStatus {
            case .noAccount:
                return "Нет iCloud"
            case .restricted:
                return "iCloud ограничен"
            case .temporarilyUnavailable:
                return "iCloud временно недоступен"
            case .couldNotDetermine:
                return isCloudActive ? "iCloud проверяется" : "iCloud fallback"
            case .unknown, .available:
                break
            }
        }
        switch (isCloudRequested, isCloudActive) {
        case (true, true):
            return "iCloud активен"
        case (true, false):
            return "iCloud fallback"
        case (false, _):
            return "Локально"
        }
    }

    var detailsLabel: String {
        if isCloudRequested {
            switch accountStatus {
            case .noAccount:
                return "CloudKit-store готов, но в этой среде нет входа в iCloud."
            case .restricted:
                return "iCloud аккаунт ограничен системными настройками."
            case .temporarilyUnavailable:
                return "iCloud временно недоступен; локальные данные остаются источником правды."
            case .couldNotDetermine:
                return "Не удалось определить iCloud account status; локальный слой остаётся активным."
            case .unknown, .available:
                break
            }
        }
        switch (requestedMode, activeMode) {
        case (.privateCloudKit(let requested), .privateCloudKit(let active)) where requested == active:
            return "SwiftData синхронизирует лёгкие данные через CloudKit private database."
        case (.privateCloudKit(let requested), .privateCloudKit(let active)):
            return "Запрошен \(requested), активен \(active)."
        case (.privateCloudKit(let requested), .localOnly):
            return "Запрошен \(requested), но приложение работает локально до доступности iCloud."
        case (.localOnly, .localOnly):
            return "Локальный SwiftData store без облачной синхронизации."
        case (.localOnly, .privateCloudKit(let active)):
            return "Активен CloudKit контейнер \(active)."
        }
    }
}

private struct AppleSyncStatusKey: EnvironmentKey {
    static let defaultValue = AppleSyncStatus.localOnly
}

extension EnvironmentValues {
    var appleSyncStatus: AppleSyncStatus {
        get { self[AppleSyncStatusKey.self] }
        set { self[AppleSyncStatusKey.self] = newValue }
    }
}
