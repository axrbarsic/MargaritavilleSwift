import Foundation

enum AppIdentity {
    static let displayName = "Margaritaville"
    static let bundleIdentifier = "com.alex.margaritaville.swift"
    static let applicationSupportDirectoryName = "MargaritavilleSwift"
    static let legacyApplicationSupportDirectoryNames = ["OceanKeySwift"]
    static let loggerSubsystem = bundleIdentifier
    static let presetBackupTypeIdentifier = "com.alex.margaritaville.presetbackup"
    static let presetBackupFilenamePrefix = "Margaritaville-Presets"
    static let scheduleNotificationTitle = displayName
    static let scheduleNotificationIdentifierPrefix = "margaritaville.room.schedule"
}
