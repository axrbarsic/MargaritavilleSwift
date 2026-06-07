import SwiftUI

@main
struct OceanKeySwiftApp: App {
    @State private var workSession: WorkSessionStore
    @State private var appSettings: AppSettingsStore
    @State private var performanceTelemetry: PerformanceTelemetryStore
    @State private var didRequestWorkSessionLoad = false
    private let workSessionRepository: SwiftDataWorkSessionRepository
    private let interactionFeedback = InteractionFeedbackService()
    private let scheduleNotifications = LocalScheduleNotificationService()

    init() {
        let repository = SwiftDataWorkSessionRepository()
        workSessionRepository = repository
        _workSession = State(initialValue: WorkSessionStore.bootstrapping(repository: repository))
        _appSettings = State(initialValue: AppSettingsStore.load())
        _performanceTelemetry = State(initialValue: PerformanceTelemetryStore())
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                workSession: workSession,
                appSettings: appSettings,
                performanceTelemetry: performanceTelemetry
            )
                .environment(\.interactionFeedback, .live(interactionFeedback))
                .environment(\.scheduleNotifications, .live(scheduleNotifications))
                .onAppear {
                    performanceTelemetry.start()
                }
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
