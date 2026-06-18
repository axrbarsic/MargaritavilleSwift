import Foundation

extension AppSettingsStore {
    func resetToDefaults() {
        appBackgroundMode = .matrixRain
        roomCellGeometry = .roomy
        roomTaskLongPress = true
        summaryActionMenuAllowsMultiple = false
        housekeeperDetailsGestureMode = .longPress
        personalCartMarkers = .default
        statusPaletteSaturation = 1
        matrixSpeed = MatrixRainConfiguration.default.speed
        backgroundVideoRelativePath = nil
        backgroundVideoBlur = 0.28
        backgroundVideoBrightness = 0.08
        backgroundVideoGreenTint = 0.34
        backgroundVideoGridIntensity = 0
        tvStaticVariant = TVStaticNoiseConfiguration.default.variant
        tvStaticSpeed = TVStaticNoiseConfiguration.default.speed
        tvStaticParticleSize = TVStaticNoiseConfiguration.default.particleSize
        tvStaticBrightness = TVStaticNoiseConfiguration.default.brightness
        tvStaticGreenTint = TVStaticNoiseConfiguration.default.greenTint
        developerCellPhysicsEnabled = false
        developerCellSpringIntensity = 0.72
        developerCellSpringSpeed = 0.82
        deepSeekModelTier = .pro
        developerVIPFlickerEnabled = false
        developerVIPFlickerSpeed = 1.6
        developerVIPJellyEnabled = true
        developerVIPJellySpeed = 0.75
        selectedHotelID = nil
        housekeepers = MargaritavilleHousekeeperCatalog.defaultHousekeepers
        cartConsumableCatalog = CartConsumableCatalog.defaultCatalog
    }
}
