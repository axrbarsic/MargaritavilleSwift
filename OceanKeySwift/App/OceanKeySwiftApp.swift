import SwiftUI

@main
struct OceanKeySwiftApp: App {
    @State private var workSession = WorkSessionStore.load()

    var body: some Scene {
        WindowGroup {
            AppRootView(workSession: workSession)
        }
    }
}
