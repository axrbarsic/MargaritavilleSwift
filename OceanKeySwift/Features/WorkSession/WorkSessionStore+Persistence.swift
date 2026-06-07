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
        selection = snapshot.selection
        carts = snapshot.carts
        lastPersistenceError = nil
    }

    func recordLoadFailure(_ failure: WorkSessionLoadFailure) {
        lastPersistenceError = failure
    }

    func persist() {
        guard let repository else { return }
        repository.save(snapshot: WorkSessionSnapshot(selection: selection, carts: carts))
        lastPersistenceError = nil
    }

    static func bootstrapping(repository: WorkSessionRepository = SwiftDataWorkSessionRepository()) -> WorkSessionStore {
        WorkSessionStore(carts: seedCarts(), repository: repository)
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

    static func load(repository: WorkSessionRepository = SwiftDataWorkSessionRepository()) -> WorkSessionStore {
        do {
            if let snapshot = try repository.loadSnapshot() {
                return WorkSessionStore(
                    carts: snapshot.carts,
                    selection: snapshot.selection,
                    repository: repository
                )
            }
        } catch {
            let store = WorkSessionStore(carts: seedCarts(), repository: repository)
            store.lastPersistenceError = error
            return store
        }
        return WorkSessionStore(carts: seedCarts(), repository: repository)
    }

    static func preview() -> WorkSessionStore {
        WorkSessionStore(carts: seedCarts())
    }

    private static func seedCarts() -> [CartSection] {
        [
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
