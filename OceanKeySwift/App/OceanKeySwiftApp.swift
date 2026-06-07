import SwiftUI

@main
struct OceanKeySwiftApp: App {
    @State private var workSession = WorkSessionStore.load()
    @State private var appSettings = AppSettingsStore.load()
    private let interactionFeedback = InteractionFeedbackService()
    private let scheduleNotifications = LocalScheduleNotificationService()

    var body: some Scene {
        WindowGroup {
            AppRootView(workSession: workSession, appSettings: appSettings)
                .environment(\.interactionFeedback, .live(interactionFeedback))
                .environment(\.scheduleNotifications, .live(scheduleNotifications))
        }
    }
}
