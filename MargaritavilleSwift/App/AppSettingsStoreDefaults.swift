import BrooklynBackgroundKit
import Foundation

extension AppSettingsStore {
    func resetToDefaults() {
        appBackgroundMode = .matrixRain
        brooklynSurfaceStyle = .donorExact
        resetBrooklynAppearance()
        roomCellGeometry = .roomy
        margaritavilleGridColumnCount = .four
        transparentSurfacesEnabled = false
        roomTaskLongPress = true
        summaryActionMenuAllowsMultiple = false
        housekeeperDetailsGestureMode = .longPress
        personalCartMarkers = .default
        interactionSoundAssignments = InteractionSoundAssignments()
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
        developerLive3DCellsEnabled = false
        developerCellSpringIntensity = 0.72
        developerCellSpringSpeed = 0.82
        deepSeekModelTier = .pro
        developerVIPFlickerEnabled = false
        developerVIPFlickerSpeed = 1.6
        developerVIPJellyEnabled = true
        developerVIPJellySpeed = 0.75
        developerVIPHDREnabled = false
        developerStatusHDRPulseEnabled = false
        selectedHotelID = nil
        housekeepers = MargaritavilleHousekeeperCatalog.defaultHousekeepers
        cartConsumableCatalog = CartConsumableCatalog.defaultCatalog
    }

    func resetBrooklynAppearance() {
        brooklynCellScale = BrooklynAppearance.default.cellScale
        brooklynHue = BrooklynAppearance.default.hue
        brooklynBrightness = BrooklynAppearance.default.brightness
        brooklynContrast = BrooklynAppearance.default.contrast
    }
}
