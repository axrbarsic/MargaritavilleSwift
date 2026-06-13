import CloudKit
import SwiftUI

@main
struct MargaritavilleSwiftApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var workSession: WorkSessionStore
    @State private var appSettings: AppSettingsStore
    @State private var activeHotel: HotelProfile
    @State private var workSessionRepository: SwiftDataWorkSessionRepository
    @State private var aiVisualPresetStore: AIVisualPresetStore
    @State private var performanceTelemetry: PerformanceTelemetryStore
    @State private var appleSyncStatus: AppleSyncStatus
    @State private var didRequestWorkSessionLoad = false
    @State private var didRequestAppleSyncStatus = false
    private let interactionFeedback = InteractionFeedbackService()
    private let scheduleNotifications = LocalScheduleNotificationService()

    init() {
        let settings = AppSettingsStore.load()
        let bootProfile = HotelProfile.margaritaville
        settings.selectedHotelID = bootProfile.id
        let repository = SwiftDataWorkSessionRepository(
            hotelID: bootProfile.id,
            syncMode: AppleSyncConfiguration.defaultSyncMode
        )
        _workSessionRepository = State(initialValue: repository)
        _workSession = State(initialValue: WorkSessionStore.bootstrapping(
            hotelProfile: bootProfile,
            repository: repository
        ))
        _appSettings = State(initialValue: settings)
        _activeHotel = State(initialValue: bootProfile)
        _aiVisualPresetStore = State(initialValue: Self.makeAIVisualPresetStore())
        _performanceTelemetry = State(initialValue: PerformanceTelemetryStore())
        _appleSyncStatus = State(initialValue: .repository(repository))
    }

    @MainActor
    private static func makeAIVisualPresetStore() -> AIVisualPresetStore {
        if !AppleSyncConfiguration.canUsePrivateCloudKitAtRuntime() {
            return (try? AIVisualPresetStore(
                localFallbackReason: "У текущей сборки нет iCloud/CloudKit entitlement. Используй ручной backup в Файлы/iCloud Drive."
            )) ?? Self.makeInMemoryAIVisualPresetStore()
        }
        do {
            return try AIVisualPresetStore()
        } catch {
            return (try? AIVisualPresetStore(localFallbackReason: error.localizedDescription))
                ?? Self.makeInMemoryAIVisualPresetStore()
        }
    }

    @MainActor
    private static func makeInMemoryAIVisualPresetStore() -> AIVisualPresetStore {
        do {
            return try AIVisualPresetStore(inMemory: true)
        } catch {
            return AIVisualPresetStore.emptyMemoryOnly(lastError: error.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                workSession: workSession,
                appSettings: appSettings,
                aiVisualPresetStore: aiVisualPresetStore,
                performanceTelemetry: performanceTelemetry,
                interactionFeedbackService: interactionFeedback,
                activeHotel: activeHotel,
                onSelectHotel: selectHotel
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
                .onChange(of: scenePhase) { _, phase in
                    guard phase != .active else { return }
                    workSession.flushPendingPersistence()
                }
        }
    }

    @MainActor
    private func selectHotel(_ hotelProfile: HotelProfile) {
        guard hotelProfile.id == HotelProfile.margaritaville.id else { return }
        let repository = SwiftDataWorkSessionRepository(
            hotelID: hotelProfile.id,
            syncMode: AppleSyncConfiguration.defaultSyncMode
        )
        workSessionRepository = repository
        workSession = WorkSessionStore.bootstrapping(
            hotelProfile: hotelProfile,
            repository: repository
        )
        appSettings.selectedHotelID = hotelProfile.id
        activeHotel = hotelProfile
        appleSyncStatus = .repository(repository)
        didRequestWorkSessionLoad = false
        didRequestAppleSyncStatus = false
        Task {
            await loadWorkSessionIfNeeded()
            await refreshAppleSyncStatusIfNeeded(force: true)
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
            } else {
                workSession.finishInitialLoadWithoutSnapshot()
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
