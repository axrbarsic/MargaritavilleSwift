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
        .environment(\.appBackgroundVideoGridIntensity, appSettings.backgroundVideoGridIntensity)
        .environment(\.matrixRainConfiguration, appSettings.matrixConfiguration)
        .environment(\.tvStaticNoiseConfiguration, appSettings.tvStaticNoiseConfiguration)
        .environment(\.experimentalCellPhysicsEnabled, appSettings.developerCellPhysicsEnabled)
        .environment(\.experimentalCellSpringIntensity, appSettings.developerCellSpringIntensity)
        .environment(\.experimentalCellSpringSpeed, appSettings.developerCellSpringSpeed)
        .environment(\.experimentalVIPFlickerEnabled, appSettings.developerVIPFlickerEnabled)
        .environment(\.experimentalVIPFlickerSpeed, appSettings.developerVIPFlickerSpeed)
        .environment(\.experimentalVIPJellyEnabled, appSettings.developerVIPJellyEnabled)
        .environment(\.experimentalVIPJellySpeed, appSettings.developerVIPJellySpeed)
        .environment(
            \.interactionFeedback,
            .live(interactionFeedbackService)
        )
        .preferredColorScheme(.dark)
    }
}
