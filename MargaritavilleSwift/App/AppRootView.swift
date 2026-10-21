import SwiftUI

struct AppRootView: View {
    @Bindable var workSession: WorkSessionStore
    @Bindable var appSettings: AppSettingsStore
    @Bindable var aiVisualPresetStore: AIVisualPresetStore
    @Bindable var performanceTelemetry: PerformanceTelemetryStore
    let interactionFeedbackService: InteractionFeedbackService
    let activeHotel: HotelProfile
    let onSelectHotel: (HotelProfile) -> Void
    let onRetryWorkSessionLoad: () -> Void

    var body: some View {
        NavigationStack {
            if !workSession.hasLoadedInitialSnapshot {
                StartupLoadingScreen()
            } else if let loadFailure = workSession.loadFailure {
                WorkSessionLoadFailureScreen(failure: loadFailure, onRetry: onRetryWorkSessionLoad)
            } else if workSession.selection.workdayLocked {
                SummaryScreen(
                    workSession: workSession,
                    appSettings: appSettings,
                    aiVisualPresetStore: aiVisualPresetStore,
                    performanceTelemetry: performanceTelemetry,
                    activeHotel: activeHotel,
                    onSelectHotel: onSelectHotel
                )
            } else {
                WorkSetupScreen(
                    workSession: workSession,
                    appSettings: appSettings,
                    aiVisualPresetStore: aiVisualPresetStore,
                    performanceTelemetry: performanceTelemetry,
                    activeHotel: activeHotel,
                    onSelectHotel: onSelectHotel
                )
            }
        }
        .environment(\.appBackgroundMode, appSettings.appBackgroundMode)
        .environment(\.brooklynSurfaceStyle, appSettings.brooklynSurfaceStyle)
        .environment(\.brooklynWebConfiguration, appSettings.brooklynWebConfiguration)
        .environment(\.appBackgroundVideoURL, appSettings.backgroundVideoURL)
        .environment(\.appBackgroundVideoBlur, appSettings.backgroundVideoBlur)
        .environment(\.appBackgroundVideoBrightness, appSettings.backgroundVideoBrightness)
        .environment(\.appBackgroundVideoGreenTint, appSettings.backgroundVideoGreenTint)
        .environment(\.appBackgroundVideoGridIntensity, appSettings.backgroundVideoGridIntensity)
        .environment(\.matrixRainConfiguration, appSettings.matrixConfiguration)
        .environment(\.tvStaticNoiseConfiguration, appSettings.tvStaticNoiseConfiguration)
        .environment(\.experimentalCellPhysicsEnabled, appSettings.developerCellPhysicsEnabled)
        .environment(\.experimentalLive3DCellsEnabled, appSettings.developerLive3DCellsEnabled)
        .environment(\.experimentalCellSpringIntensity, appSettings.developerCellSpringIntensity)
        .environment(\.experimentalCellSpringSpeed, appSettings.developerCellSpringSpeed)
        .environment(\.experimentalVIPJellyEnabled, appSettings.developerVIPJellyEnabled)
        .environment(\.experimentalVIPJellySpeed, appSettings.developerVIPJellySpeed)
        .environment(\.experimentalVIPHDREnabled, appSettings.developerVIPHDREnabled)
        .environment(\.experimentalStatusHDRPulseEnabled, appSettings.developerStatusHDRPulseEnabled)
        .environment(\.interactionSoundAssignments, appSettings.interactionSoundAssignments)
        .environment(
            \.interactionFeedback,
            .live(
                interactionFeedbackService,
                hapticsV2: true,
                soundAssignments: appSettings.interactionSoundAssignments
            )
        )
        .onAppear {
            AppSurfaceTransparency.apply(appSettings.transparentSurfacesEnabled)
        }
        .onChange(of: appSettings.transparentSurfacesEnabled) { _, isEnabled in
            AppSurfaceTransparency.apply(isEnabled)
        }
        .preferredColorScheme(.dark)
    }
}

private struct StartupLoadingScreen: View {
    var body: some View {
        ZStack {
            AppBackgroundView()
            ProgressView()
                .controlSize(.large)
                .tint(.white)
        }
    }
}
