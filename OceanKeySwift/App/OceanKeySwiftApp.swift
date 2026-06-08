import CloudKit
import SwiftUI

@main
struct OceanKeySwiftApp: App {
    @State private var workSession: WorkSessionStore
    @State private var appSettings: AppSettingsStore
    @State private var performanceTelemetry: PerformanceTelemetryStore
    @State private var appleSyncStatus: AppleSyncStatus
    @State private var didRequestWorkSessionLoad = false
    @State private var didRequestAppleSyncStatus = false
    private let workSessionRepository: SwiftDataWorkSessionRepository
    private let interactionFeedback = InteractionFeedbackService()
    private let scheduleNotifications = LocalScheduleNotificationService()

    init() {
        let repository = SwiftDataWorkSessionRepository(syncMode: AppleSyncConfiguration.defaultSyncMode)
        workSessionRepository = repository
        _workSession = State(initialValue: WorkSessionStore.bootstrapping(repository: repository))
        _appSettings = State(initialValue: AppSettingsStore.load())
        _performanceTelemetry = State(initialValue: PerformanceTelemetryStore())
        _appleSyncStatus = State(initialValue: .repository(repository))
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                workSession: workSession,
                appSettings: appSettings,
                performanceTelemetry: performanceTelemetry,
                interactionFeedbackService: interactionFeedback
            )
                .environment(\.appleSyncStatus, appleSyncStatus)
                .environment(\.scheduleNotifications, .live(scheduleNotifications))
                .onAppear {
                    performanceTelemetry.start()
                }
                .task {
                    await loadWorkSessionIfNeeded()
                    await refreshAppleSyncStatusIfNeeded()
                }
                .onReceive(NotificationCenter.default.publisher(for: .CKAccountChanged)) { _ in
                    Task {
                        await refreshAppleSyncStatusIfNeeded(force: true)
                    }
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

    @MainActor
    private func refreshAppleSyncStatusIfNeeded(force: Bool = false) async {
        guard force || !didRequestAppleSyncStatus else { return }
        didRequestAppleSyncStatus = true
        var status = AppleSyncStatus.repository(workSessionRepository)
        if case .privateCloudKit(let containerIdentifier) = workSessionRepository.syncMode {
            status.accountStatus = await AppleCloudAccountProbe.status(containerIdentifier: containerIdentifier)
        }
        appleSyncStatus = status
    }
}
