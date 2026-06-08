import SwiftUI

struct AppRootView: View {
    @Bindable var workSession: WorkSessionStore
    @Bindable var appSettings: AppSettingsStore
    @Bindable var performanceTelemetry: PerformanceTelemetryStore

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
        .environment(\.matrixRainConfiguration, appSettings.matrixConfiguration)
        .environment(\.experimentalLiquidGlassEnabled, appSettings.developerLiquidGlassEnabled)
        .environment(\.experimentalGlassVIPEnabled, appSettings.developerGlassVIPEnabled)
        .environment(\.experimentalMetalAuroraEnabled, appSettings.developerMetalAuroraEnabled)
        .preferredColorScheme(.dark)
    }
}
