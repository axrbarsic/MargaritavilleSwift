import SwiftUI

@main
struct OceanKeySwiftApp: App {
    @State private var workSession: WorkSessionStore
    @State private var appSettings: AppSettingsStore
    @State private var didRequestWorkSessionLoad = false
    private let workSessionRepository: SwiftDataWorkSessionRepository
    private let interactionFeedback = InteractionFeedbackService()
    private let scheduleNotifications = LocalScheduleNotificationService()

    init() {
        let repository = SwiftDataWorkSessionRepository()
        workSessionRepository = repository
        _workSession = State(initialValue: WorkSessionStore.bootstrapping(repository: repository))
        _appSettings = State(initialValue: AppSettingsStore.load())
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(workSession: workSession, appSettings: appSettings)
                .environment(\.interactionFeedback, .live(interactionFeedback))
                .environment(\.scheduleNotifications, .live(scheduleNotifications))
                .task {
                    await loadWorkSessionIfNeeded()
                }
        }
    }

    @MainActor
    private func loadWorkSessionIfNeeded() async {
        guard !didRequestWorkSessionLoad else { return }
        didRequestWorkSessionLoad = true
        switch await WorkSessionStore.loadSnapshot(repository: workSessionRepository) {
        case .success(let snapshot):
            if let snapshot {
                workSession.apply(snapshot: snapshot)
            }
        case .failure(let failure):
            workSession.recordLoadFailure(failure)
        }
    }
}
