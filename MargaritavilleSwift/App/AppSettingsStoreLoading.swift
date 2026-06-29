import Foundation

extension AppSettingsStore {
    static func load(userDefaults: UserDefaults = .standard) -> AppSettingsStore {
        let backgroundRawValue = userDefaults.string(forKey: Keys.appBackgroundMode)
        let appBackgroundMode = backgroundRawValue.flatMap(AppBackgroundMode.init(rawValue:)) ?? .matrixRain
        let rawValue = userDefaults.string(forKey: Keys.roomCellGeometry)
        let geometry = rawValue.flatMap(RoomCellGeometry.init(rawValue:)) ?? .roomy
        let transparentSurfacesEnabled = userDefaults.object(forKey: Keys.transparentSurfacesEnabled) as? Bool ?? false
        let roomTaskLongPress = userDefaults.object(forKey: Keys.roomTaskLongPress) as? Bool ?? true
        let summaryActionMenuAllowsMultiple = userDefaults.object(forKey: Keys.summaryActionMenuAllowsMultiple) as? Bool ?? false
        let housekeeperDetailsGestureMode = userDefaults.string(forKey: Keys.housekeeperDetailsGestureMode)
            .flatMap(HousekeeperDetailsGestureMode.init(rawValue:))
            ?? .tap
        let personalCartMarkers = Self.loadPersonalCartMarkers(userDefaults: userDefaults)
        let interactionSoundAssignments = Self.loadInteractionSoundAssignments(userDefaults: userDefaults)
        let statusPaletteSaturation = userDefaults.object(forKey: Keys.statusPaletteSaturation) as? Double ?? 1
        let matrixSpeed = userDefaults.object(forKey: Keys.matrixSpeed) as? Double
            ?? MatrixRainConfiguration.default.speed
        let backgroundVideoRelativePath = userDefaults.string(forKey: Keys.backgroundVideoRelativePath)
        let backgroundVideoBlur = userDefaults.object(forKey: Keys.backgroundVideoBlur) as? Double ?? 0.28
        let backgroundVideoBrightness = userDefaults.object(forKey: Keys.backgroundVideoBrightness) as? Double ?? 0.08
        let backgroundVideoGreenTint = userDefaults.object(forKey: Keys.backgroundVideoGreenTint) as? Double ?? 0.34
        let backgroundVideoGridIntensity = userDefaults.object(forKey: Keys.backgroundVideoGridIntensity) as? Double ?? 0
        let tvStaticSpeed = userDefaults.object(forKey: Keys.tvStaticSpeed) as? Double
            ?? TVStaticNoiseConfiguration.default.speed
        let tvStaticParticleSize = userDefaults.object(forKey: Keys.tvStaticParticleSize) as? Double
            ?? TVStaticNoiseConfiguration.default.particleSize
        let tvStaticBrightness = userDefaults.object(forKey: Keys.tvStaticBrightness) as? Double
            ?? TVStaticNoiseConfiguration.default.brightness
        let tvStaticGreenTint = userDefaults.object(forKey: Keys.tvStaticGreenTint) as? Double
            ?? TVStaticNoiseConfiguration.default.greenTint
        let tvStaticVariant = userDefaults.string(forKey: Keys.tvStaticVariant)
            .flatMap(TVStaticNoiseVariant.init(rawValue:))
            ?? TVStaticNoiseConfiguration.default.variant
        let developerCellPhysicsEnabled = userDefaults.object(forKey: Keys.developerCellPhysicsEnabled) as? Bool ?? false
        let developerCellSpringIntensity = userDefaults.object(forKey: Keys.developerCellSpringIntensity) as? Double ?? 0.72
        let developerCellSpringSpeed = userDefaults.object(forKey: Keys.developerCellSpringSpeed) as? Double ?? 0.82
        let deepSeekModelTier = userDefaults.string(forKey: Keys.deepSeekModelTier)
            .flatMap(DeepSeekModelTier.init(rawValue:))
            ?? .pro
        let developerVIPFlickerEnabled = userDefaults.object(forKey: Keys.developerVIPFlickerEnabled) as? Bool ?? false
        let developerVIPFlickerSpeed = userDefaults.object(forKey: Keys.developerVIPFlickerSpeed) as? Double ?? 1.6
        let developerVIPJellyEnabled = Self.migratedDeveloperVIPJellyEnabled(userDefaults: userDefaults)
        let developerVIPJellySpeed = userDefaults.object(forKey: Keys.developerVIPJellySpeed) as? Double ?? 0.75
        let selectedHotelID = userDefaults.string(forKey: Keys.selectedHotelID)
        let housekeepers = Self.loadHousekeepers(userDefaults: userDefaults)
        let cartConsumableCatalog = Self.loadCartConsumableCatalog(userDefaults: userDefaults)
        return AppSettingsStore(
            appBackgroundMode: appBackgroundMode,
            roomCellGeometry: geometry,
            transparentSurfacesEnabled: transparentSurfacesEnabled,
            roomTaskLongPress: roomTaskLongPress,
            summaryActionMenuAllowsMultiple: summaryActionMenuAllowsMultiple,
            housekeeperDetailsGestureMode: housekeeperDetailsGestureMode,
            personalCartMarkers: personalCartMarkers,
            interactionSoundAssignments: interactionSoundAssignments,
            statusPaletteSaturation: statusPaletteSaturation,
            matrixSpeed: matrixSpeed,
            backgroundVideoRelativePath: backgroundVideoRelativePath,
            backgroundVideoBlur: backgroundVideoBlur,
            backgroundVideoBrightness: backgroundVideoBrightness,
            backgroundVideoGreenTint: backgroundVideoGreenTint,
            backgroundVideoGridIntensity: backgroundVideoGridIntensity,
            tvStaticVariant: tvStaticVariant,
            tvStaticSpeed: tvStaticSpeed,
            tvStaticParticleSize: tvStaticParticleSize,
            tvStaticBrightness: tvStaticBrightness,
            tvStaticGreenTint: tvStaticGreenTint,
            developerCellPhysicsEnabled: developerCellPhysicsEnabled,
            developerCellSpringIntensity: developerCellSpringIntensity,
            developerCellSpringSpeed: developerCellSpringSpeed,
            deepSeekModelTier: deepSeekModelTier,
            developerVIPFlickerEnabled: developerVIPFlickerEnabled,
            developerVIPFlickerSpeed: developerVIPFlickerSpeed,
            developerVIPJellyEnabled: developerVIPJellyEnabled,
            developerVIPJellySpeed: developerVIPJellySpeed,
            selectedHotelID: selectedHotelID,
            housekeepers: housekeepers,
            cartConsumableCatalog: cartConsumableCatalog,
            userDefaults: userDefaults
        )
    }

    static func normalizedStatusPaletteSaturation(_ value: Double) -> Double {
        min(max(value, 0.70), 1.65)
    }

    private static func migratedDeveloperVIPJellyEnabled(userDefaults: UserDefaults) -> Bool {
        if userDefaults.bool(forKey: Keys.developerVIPJellyDefaultEnabledMigration) {
            return userDefaults.object(forKey: Keys.developerVIPJellyEnabled) as? Bool ?? true
        }
        userDefaults.set(true, forKey: Keys.developerVIPJellyEnabled)
        userDefaults.set(true, forKey: Keys.developerVIPJellyDefaultEnabledMigration)
        return true
    }

    private static func loadPersonalCartMarkers(userDefaults: UserDefaults) -> PersonalCartMarkers {
        guard let data = userDefaults.data(forKey: Keys.personalCartMarkers),
              let decoded = try? JSONDecoder().decode(PersonalCartMarkers.self, from: data)
        else {
            return .default
        }
        return decoded.normalized()
    }

    static func savePersonalCartMarkers(_ markers: PersonalCartMarkers, userDefaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(markers.normalized()) else { return }
        userDefaults.set(data, forKey: Keys.personalCartMarkers)
    }

    private static func loadInteractionSoundAssignments(userDefaults: UserDefaults) -> InteractionSoundAssignments {
        guard let data = userDefaults.data(forKey: Keys.interactionSoundAssignments),
              let decoded = try? JSONDecoder().decode(InteractionSoundAssignments.self, from: data)
        else {
            return InteractionSoundAssignments()
        }
        return decoded
    }

    static func saveInteractionSoundAssignments(
        _ assignments: InteractionSoundAssignments,
        userDefaults: UserDefaults
    ) {
        guard let data = try? JSONEncoder().encode(assignments) else { return }
        userDefaults.set(data, forKey: Keys.interactionSoundAssignments)
    }

    static func loadHousekeepers(userDefaults: UserDefaults) -> [Housekeeper] {
        guard let data = userDefaults.data(forKey: Keys.housekeepers),
              let decoded = try? JSONDecoder().decode([Housekeeper].self, from: data)
        else {
            return MargaritavilleHousekeeperCatalog.defaultHousekeepers
        }
        let normalized = MargaritavilleHousekeeperCatalog.normalizedHousekeepers(decoded)
        return normalized.isEmpty ? MargaritavilleHousekeeperCatalog.defaultHousekeepers : normalized
    }

    static func saveHousekeepers(_ housekeepers: [Housekeeper], userDefaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(
            MargaritavilleHousekeeperCatalog.normalizedHousekeepers(housekeepers)
        ) else { return }
        userDefaults.set(data, forKey: Keys.housekeepers)
    }

    static func loadCartConsumableCatalog(userDefaults: UserDefaults) -> [CartConsumableCatalogItem] {
        guard let data = userDefaults.data(forKey: Keys.cartConsumableCatalog),
              let decoded = try? JSONDecoder().decode([CartConsumableCatalogItem].self, from: data)
        else {
            return CartConsumableCatalog.defaultCatalog
        }
        let normalized = CartConsumableCatalog.normalizedCatalog(decoded)
        return normalized.isEmpty ? CartConsumableCatalog.defaultCatalog : normalized
    }

    static func saveCartConsumableCatalog(_ items: [CartConsumableCatalogItem], userDefaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(CartConsumableCatalog.normalizedCatalog(items)) else { return }
        userDefaults.set(data, forKey: Keys.cartConsumableCatalog)
    }

    static func normalizedMatrixSpeed(_ value: Double) -> Double {
        min(max(value, 0.08), 3.0)
    }

    static func normalizedBackgroundVideoBlur(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    static func normalizedBackgroundVideoBrightness(_ value: Double) -> Double {
        min(max(value, -0.85), 0.85)
    }

    static func normalizedBackgroundVideoGreenTint(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    static func normalizedBackgroundVideoGridIntensity(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    static func normalizedTVStaticSpeed(_ value: Double) -> Double {
        min(max(value, 0.2), 3.0)
    }

    static func normalizedTVStaticParticleSize(_ value: Double) -> Double {
        min(max(value, 0.5), 2.5)
    }

    static func normalizedTVStaticBrightness(_ value: Double) -> Double {
        min(max(value, -1), 1)
    }

    static func normalizedTVStaticGreenTint(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    static func normalizedDeveloperCellSpringIntensity(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    static func normalizedDeveloperCellSpringSpeed(_ value: Double) -> Double {
        min(max(value, 0.2), 1.6)
    }

    static func normalizedDeveloperVIPFlickerSpeed(_ value: Double) -> Double {
        min(max(value, 0.4), 4.0)
    }

    static func normalizedDeveloperVIPJellySpeed(_ value: Double) -> Double {
        min(max(value, 0.2), 2.5)
    }
}
