import SwiftUI

struct AppRootView: View {
    @Bindable var workSession: WorkSessionStore
    @Bindable var appSettings: AppSettingsStore
    @Bindable var performanceTelemetry: PerformanceTelemetryStore
    let interactionFeedbackService: InteractionFeedbackService

    var body: some View {
        NavigationStack {
            if workSession.selection.workdayLocked {
                SummaryScreen(
                    workSession: workSession,
                    appSettings: appSettings,
                    performanceTelemetry: performanceTelemetry
                )
            } else {
                WorkSetupScreen(
                    workSession: workSession,
                    appSettings: appSettings,
                    performanceTelemetry: performanceTelemetry
                )
            }
        }
        .environment(\.appBackgroundMode, appSettings.appBackgroundMode)
        .environment(\.appBackgroundVideoURL, appSettings.backgroundVideoURL)
        .environment(\.appBackgroundVideoBlur, appSettings.backgroundVideoBlur)
        .environment(\.appBackgroundVideoBrightness, appSettings.backgroundVideoBrightness)
        .environment(\.appBackgroundVideoGreenTint, appSettings.backgroundVideoGreenTint)
        .environment(\.matrixRainConfiguration, appSettings.matrixConfiguration)
        .environment(\.experimentalLiquidGlassEnabled, appSettings.developerLiquidGlassEnabled)
        .environment(\.experimentalGlassVIPEnabled, appSettings.developerGlassVIPEnabled)
        .environment(\.experimentalMetalAuroraEnabled, appSettings.developerMetalAuroraEnabled)
        .environment(\.experimentalSoundPackV2Enabled, appSettings.developerSoundPackV2Enabled)
        .environment(\.experimentalHapticsV2Enabled, appSettings.developerHapticsV2Enabled)
        .environment(\.experimentalVIPParticlesEnabled, appSettings.developerVIPParticlesEnabled)
        .environment(\.experimentalCellPhysicsEnabled, appSettings.developerCellPhysicsEnabled)
        .environment(\.experimentalAssistantObjectEnabled, appSettings.developerAssistantObjectEnabled)
        .environment(\.experimentalCellVolumeEnabled, appSettings.developerCellVolumeEnabled)
        .environment(\.experimentalCellVolumeIntensity, appSettings.developerCellVolumeIntensity)
        .environment(\.experimentalCellSpringIntensity, appSettings.developerCellSpringIntensity)
        .environment(\.experimentalCellSpringSpeed, appSettings.developerCellSpringSpeed)
        .environment(\.experimentalVIPZebraIntensity, appSettings.developerVIPZebraIntensity)
        .environment(\.experimentalVIPZebraSpeed, appSettings.developerVIPZebraSpeed)
        .environment(
            \.interactionFeedback,
            .live(
                interactionFeedbackService,
                soundPackV2: appSettings.developerSoundPackV2Enabled,
                hapticsV2: appSettings.developerHapticsV2Enabled
            )
        )
        .preferredColorScheme(.dark)
    }
}
