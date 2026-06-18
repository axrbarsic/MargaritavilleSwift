import SwiftUI

struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var idleManager = AppIdleManager()
    @Bindable var workSession: WorkSessionStore
    @Bindable var appSettings: AppSettingsStore
    @Bindable var aiVisualPresetStore: AIVisualPresetStore
    @Bindable var performanceTelemetry: PerformanceTelemetryStore
    let interactionFeedbackService: InteractionFeedbackService
    let activeHotel: HotelProfile
    let onSelectHotel: (HotelProfile) -> Void

    var body: some View {
        ZStack {
            NavigationStack {
                if !workSession.hasLoadedInitialSnapshot {
                    StartupLoadingScreen()
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
            .blur(radius: (idleManager.isIdle && appSettings.idleScreensaverEnabled) ? 8 : 0)
            .animation(.easeInOut(duration: 0.4), value: idleManager.isIdle)

            if idleManager.isIdle && appSettings.idleScreensaverEnabled {
                ScreensaverOverlayView(
                    mode: appSettings.idleScreensaverMode,
                    appSettings: appSettings,
                    onDismiss: {
                        idleManager.resetActivity()
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .background(
            UserActivityTracker {
                idleManager.resetActivity()
            }
        )
        .onAppear {
            idleManager.startTracking(timeout: appSettings.idleScreensaverTimeout)
        }
        .onChange(of: appSettings.idleScreensaverTimeout) { _, newValue in
            idleManager.updateTimeout(newValue)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                idleManager.startTracking(timeout: appSettings.idleScreensaverTimeout)
            } else {
                idleManager.stopTracking()
            }
        }
        .environment(\.appBackgroundMode, appSettings.appBackgroundMode)
        .environment(\.appBackgroundVideoURL, appSettings.backgroundVideoURL)
        .environment(\.appBackgroundVideoBlur, appSettings.backgroundVideoBlur)
        .environment(\.appBackgroundVideoBrightness, appSettings.backgroundVideoBrightness)
        .environment(\.appBackgroundVideoGreenTint, appSettings.backgroundVideoGreenTint)
        .environment(\.appBackgroundVideoGridIntensity, appSettings.backgroundVideoGridIntensity)
        .environment(\.matrixRainConfiguration, appSettings.matrixConfiguration)
        .environment(\.tvStaticNoiseConfiguration, appSettings.tvStaticNoiseConfiguration)
        .environment(\.experimentalCellPhysicsEnabled, appSettings.developerCellPhysicsEnabled)
        .environment(\.experimentalCellSpringIntensity, appSettings.developerCellSpringIntensity)
        .environment(\.experimentalCellSpringSpeed, appSettings.developerCellSpringSpeed)
        .environment(\.experimentalVIPJellyEnabled, appSettings.developerVIPJellyEnabled)
        .environment(\.experimentalVIPJellySpeed, appSettings.developerVIPJellySpeed)
        .environment(
            \.interactionFeedback,
            .live(interactionFeedbackService, soundPackV2: true, hapticsV2: true)
        )
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
