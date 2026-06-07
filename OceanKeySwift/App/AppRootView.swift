import SwiftUI

struct AppRootView: View {
    @Bindable var workSession: WorkSessionStore
    @Bindable var appSettings: AppSettingsStore

    var body: some View {
        NavigationStack {
            if workSession.selection.workdayLocked {
                SummaryScreen(workSession: workSession, appSettings: appSettings)
            } else {
                WorkSetupScreen(workSession: workSession, appSettings: appSettings)
            }
        }
        .preferredColorScheme(.dark)
    }
}
