import SwiftUI

struct AppRootView: View {
    @Bindable var workSession: WorkSessionStore
    @Bindable var appSettings: AppSettingsStore
    @Bindable var aiVisualPresetStore: AIVisualPresetStore
    @Bindable var performanceTelemetry: PerformanceTelemetryStore
    let interactionFeedbackService: InteractionFeedbackService
    let activeHotel: HotelProfile?
    let onSelectHotel: (HotelProfile) -> Void

    var body: some View {
        NavigationStack {
            if activeHotel == nil {
                HotelSelectionScreen(onSelect: onSelectHotel)
            } else if workSession.selection.workdayLocked {
                SummaryScreen(
                    workSession: workSession,
                    appSettings: appSettings,
                    aiVisualPresetStore: aiVisualPresetStore,
                    performanceTelemetry: performanceTelemetry,
                    activeHotel: activeHotel ?? workSession.hotelProfile,
                    onSelectHotel: onSelectHotel
                )
            } else {
                WorkSetupScreen(
                    workSession: workSession,
                    appSettings: appSettings,
                    aiVisualPresetStore: aiVisualPresetStore,
                    performanceTelemetry: performanceTelemetry,
                    activeHotel: activeHotel ?? workSession.hotelProfile,
                    onSelectHotel: onSelectHotel
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
        .environment(\.experimentalVIPJellyEnabled, appSettings.developerVIPJellyEnabled)
        .environment(\.experimentalVIPJellySpeed, appSettings.developerVIPJellySpeed)
        .environment(
            \.interactionFeedback,
            .live(interactionFeedbackService)
        )
        .preferredColorScheme(.dark)
    }
}
