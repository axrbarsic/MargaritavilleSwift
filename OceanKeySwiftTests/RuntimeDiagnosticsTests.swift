import Testing
@testable import OceanKeySwift

@Test
func runtimeDiagnosticsReadsProMotionOptIn() {
    #expect(RuntimeDiagnostics.proMotionOptIn(infoDictionary: ["CADisableMinimumFrameDurationOnPhone": true]))
    #expect(!RuntimeDiagnostics.proMotionOptIn(infoDictionary: [:]))
}

@Test
func appleSyncStatusReportsCloudKitAndFallbackModes() {
    let active = AppleSyncStatus(
        requestedMode: .privateCloudKit(containerIdentifier: "iCloud.com.alex.oceankey.swift"),
        activeMode: .privateCloudKit(containerIdentifier: "iCloud.com.alex.oceankey.swift"),
        accountStatus: .available
    )
    #expect(active.statusLabel == "iCloud активен")
    #expect(active.isCloudActive)

    let fallback = AppleSyncStatus(
        requestedMode: .privateCloudKit(containerIdentifier: "iCloud.com.alex.oceankey.swift"),
        activeMode: .localOnly,
        accountStatus: .unknown
    )
    #expect(fallback.statusLabel == "iCloud fallback")
    #expect(!fallback.isCloudActive)

    let noAccount = AppleSyncStatus(
        requestedMode: .privateCloudKit(containerIdentifier: "iCloud.com.alex.oceankey.swift"),
        activeMode: .privateCloudKit(containerIdentifier: "iCloud.com.alex.oceankey.swift"),
        accountStatus: .noAccount
    )
    #expect(noAccount.statusLabel == "Нет iCloud")
}

@Test
func runtimeDiagnosticsFormatsFrameRateStatus() {
    let label = RuntimeDiagnostics.proMotionStatusLabel(
        maximumFramesPerSecond: 120,
        infoDictionary: ["CADisableMinimumFrameDurationOnPhone": true]
    )

    #expect(label == "вкл, до 120 Гц")
}
