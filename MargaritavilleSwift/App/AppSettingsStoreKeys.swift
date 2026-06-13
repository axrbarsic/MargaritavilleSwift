import Foundation

extension AppSettingsStore {
    enum Keys {
        static let appBackgroundMode = "appBackgroundMode"
        static let roomCellGeometry = "roomCellGeometry"
        static let roomTaskLongPress = "roomTaskLongPress"
        static let summaryActionMenuAllowsMultiple = "summaryActionMenuAllowsMultiple"
        static let personalCartMarkers = "personalCartMarkers"
        static let statusPaletteSaturation = "statusPaletteSaturation"
        static let matrixSpeed = "matrixSpeed"
        static let backgroundVideoRelativePath = "backgroundVideoRelativePath"
        static let backgroundVideoBlur = "backgroundVideoBlur"
        static let backgroundVideoBrightness = "backgroundVideoBrightness"
        static let backgroundVideoGreenTint = "backgroundVideoGreenTint"
        static let backgroundVideoGridIntensity = "backgroundVideoGridIntensity"
        static let tvStaticVariant = "tvStaticVariant"
        static let tvStaticSpeed = "tvStaticSpeed"
        static let tvStaticParticleSize = "tvStaticParticleSize"
        static let tvStaticBrightness = "tvStaticBrightness"
        static let tvStaticGreenTint = "tvStaticGreenTint"
        static let developerCellPhysicsEnabled = "developerCellPhysicsEnabled"
        static let developerCellSpringIntensity = "developerCellSpringIntensity"
        static let developerCellSpringSpeed = "developerCellSpringSpeed"
        static let deepSeekModelTier = "deepSeekModelTier"
        static let developerVIPFlickerEnabled = "developerVIPFlickerEnabled"
        static let developerVIPFlickerSpeed = "developerVIPFlickerSpeed"
        // Keep the old key names so existing installs migrate VIP breathing into the replacement VIP jelly mode.
        static let developerVIPJellyEnabled = "developerVIPBreathingEnabled"
        static let developerVIPJellySpeed = "developerVIPBreathingSpeed"
        static let developerVIPJellyDefaultEnabledMigration = "developerVIPJellyDefaultEnabledMigration_v94"
        static let selectedHotelID = "selectedHotelID"
        static let housekeepers = "housekeepers"
    }
}
