import Foundation

struct WorkSessionLoadFailure: LocalizedError, Sendable {
    let message: String

    var errorDescription: String? { message }

    init(_ error: Error) {
        message = error.localizedDescription
    }
}

extension WorkSessionStore {
    func apply(snapshot: WorkSessionSnapshot) {
        cancelPendingPersistence()
        selection = snapshot.selection
        catalogOverrides = snapshot.catalogOverrides
        carts = snapshot.carts
        history = snapshot.history
        hasLoadedInitialSnapshot = true
        lastPersistenceError = nil
    }

    func recordLoadFailure(_ failure: WorkSessionLoadFailure) {
        cancelPendingPersistence()
        hasLoadedInitialSnapshot = true
        lastPersistenceError = failure
    }

    func finishInitialLoadWithoutSnapshot() {
        cancelPendingPersistence()
        hasLoadedInitialSnapshot = true
        lastPersistenceError = nil
    }

    func persist(immediately: Bool = false) {
        guard let repository else { return }
        guard !immediately else {
            cancelPendingPersistence()
            saveCurrentSnapshot(to: repository)
            return
        }

        pendingPersistenceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingPersistenceWorkItem = nil
            self.saveCurrentSnapshot(to: repository)
        }
        pendingPersistenceWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Self.persistenceDebounceInterval,
            execute: workItem
        )
    }

    func flushPendingPersistence() {
        guard let repository, pendingPersistenceWorkItem != nil else { return }
        cancelPendingPersistence()
        saveCurrentSnapshot(to: repository)
    }

    private func cancelPendingPersistence() {
        pendingPersistenceWorkItem?.cancel()
        pendingPersistenceWorkItem = nil
    }

    private func saveCurrentSnapshot(to repository: WorkSessionRepository) {
        repository.save(snapshot: WorkSessionSnapshot(
            selection: selection,
            catalogOverrides: catalogOverrides,
            carts: carts,
            history: history
        ))
        lastPersistenceError = nil
    }

    private static var persistenceDebounceInterval: TimeInterval {
        0.28
    }

    static func bootstrapping(
        hotelProfile: HotelProfile = .current,
        repository: WorkSessionRepository = SwiftDataWorkSessionRepository()
    ) -> WorkSessionStore {
        WorkSessionStore(
            carts: seedCarts(hotelProfile: hotelProfile),
            hasLoadedInitialSnapshot: false,
            hotelProfile: hotelProfile,
            repository: repository
        )
    }

    static func loadSnapshot(
        repository: WorkSessionRepository = SwiftDataWorkSessionRepository()
    ) async -> Result<WorkSessionSnapshot?, WorkSessionLoadFailure> {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    continuation.resume(returning: .success(try repository.loadSnapshot()))
                } catch {
                    continuation.resume(returning: .failure(WorkSessionLoadFailure(error)))
                }
            }
        }
    }

    static func load(
        hotelProfile: HotelProfile = .current,
        repository: WorkSessionRepository = SwiftDataWorkSessionRepository()
    ) -> WorkSessionStore {
        do {
            if let snapshot = try repository.loadSnapshot() {
                return WorkSessionStore(
                    carts: snapshot.carts,
                    selection: snapshot.selection,
                    catalogOverrides: snapshot.catalogOverrides,
                    history: snapshot.history,
                    hotelProfile: hotelProfile,
                    repository: repository
                )
            }
        } catch {
            let store = WorkSessionStore(
                carts: seedCarts(hotelProfile: hotelProfile),
                hotelProfile: hotelProfile,
                repository: repository
            )
            store.lastPersistenceError = error
            return store
        }
        return WorkSessionStore(
            carts: seedCarts(hotelProfile: hotelProfile),
            hotelProfile: hotelProfile,
            repository: repository
        )
    }

    static func preview() -> WorkSessionStore {
        WorkSessionStore(carts: seedCarts())
    }

    private static func seedCarts(hotelProfile: HotelProfile = .current) -> [CartSection] {
        guard hotelProfile.id == HotelProfile.current.id else { return [] }
        return [
            CartSection(id: 7, building: "A3", rooms: [
                RoomCell(id: "303", opened: true, completedTasks: Set(RoomTask.allCases), isVIP: true),
                RoomCell(id: "304", opened: true, completedTasks: Set(RoomTask.allCases), isVIP: false),
                RoomCell(id: "305", opened: true, completedTasks: Set(RoomTask.allCases), isVIP: false),
                RoomCell(
                    id: "306",
                    opened: false,
                    completedTasks: [],
                    isVIP: false,
                    scheduledTime: Calendar.current.date(bySettingHour: 10, minute: 15, second: 0, of: Date())
                ),
                RoomCell(id: "307", opened: true, completedTasks: [], isVIP: false),
                RoomCell(id: "308", opened: true, completedTasks: [.stripped], isVIP: true)
            ]),
            CartSection(id: 8, building: "A4", rooms: [
                RoomCell(id: "401", opened: false, completedTasks: [], isVIP: false),
                RoomCell(id: "402", opened: false, completedTasks: [], isVIP: false)
            ])
        ]
    }
}
