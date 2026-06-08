import Foundation
import Testing

@Test
func appDeclaresCloudKitEntitlementAndRemoteNotificationBackgroundMode() throws {
    let bundle = try #require(Bundle(identifier: "com.alex.oceankey.swift"))
    let backgroundModes = bundle.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]
    #expect(backgroundModes?.contains("remote-notification") == true)

    let entitlementsURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "OceanKeySwift/OceanKeySwift.entitlements")
    let data = try Data(contentsOf: entitlementsURL)
    let entitlements = try #require(
        PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
    )
    let containers = entitlements["com.apple.developer.icloud-container-identifiers"] as? [String]
    let services = entitlements["com.apple.developer.icloud-services"] as? [String]

    #expect(containers?.contains("iCloud.com.alex.oceankey.swift") == true)
    #expect(services?.contains("CloudKit") == true)
}
