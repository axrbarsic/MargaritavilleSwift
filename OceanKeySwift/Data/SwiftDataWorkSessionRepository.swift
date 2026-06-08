import Foundation
import OSLog
import SwiftData

final class SwiftDataWorkSessionRepository: WorkSessionRepository, @unchecked Sendable {
    enum SyncMode: Equatable, Sendable {
        case localOnly
        case privateCloudKit(containerIdentifier: String)
    }

    private static let logger = Logger(
        subsystem: "com.alex.oceankey.swift",
        category: "SwiftDataWorkSessionRepository"
    )

    private let container: ModelContainer
    private let writer: SwiftDataWorkSessionWriter
    private let legacyRepository: LocalWorkSessionRepository?
    let syncMode: SyncMode
    let activeSyncMode: SyncMode

    init(
        syncMode: SyncMode = .localOnly,
        container: ModelContainer? = nil,
        activeSyncMode: SyncMode? = nil,
        legacyRepository: LocalWorkSessionRepository? = LocalWorkSessionRepository()
    ) {
        self.syncMode = syncMode
        if let container {
            self.container = container
            self.activeSyncMode = activeSyncMode ?? syncMode
        } else {
            let resolved = SwiftDataWorkSessionRepository.makeDefaultContainer(requestedSyncMode: syncMode)
            self.container = resolved.container
            self.activeSyncMode = resolved.activeSyncMode
        }
        self.writer = SwiftDataWorkSessionWriter(container: self.container)
        self.legacyRepository = legacyRepository
    }

    convenience init(inMemory: Bool, syncMode: SyncMode = .localOnly) throws {
        let container = try SwiftDataWorkSessionRepository.makeContainer(inMemory: inMemory, syncMode: syncMode)
        self.init(
            syncMode: syncMode,
            container: container,
            activeSyncMode: inMemory ? .localOnly : syncMode,
            legacyRepository: nil
        )
    }

    func loadSnapshot() throws -> WorkSessionSnapshot? {
        let context = ModelContext(container)
        if let snapshot = try loadSwiftDataSnapshot(in: context) {
            return snapshot
        }
        guard let legacySnapshot = try legacyRepository?.loadSnapshot() else { return nil }
        try PersistentWorkSessionMapper.upsert(snapshot: legacySnapshot, in: context)
        try context.save()
        return legacySnapshot
    }

    func save(snapshot: WorkSessionSnapshot) {
        writer.save(snapshot)
    }

    func saveImmediately(snapshot: WorkSessionSnapshot) throws {
        let context = ModelContext(container)
        try PersistentWorkSessionMapper.upsert(snapshot: snapshot, in: context)
        try context.save()
    }

    private func loadSwiftDataSnapshot(in context: ModelContext) throws -> WorkSessionSnapshot? {
        var descriptor = FetchDescriptor<PersistentWorkSession>(
            predicate: #Predicate { $0.id == "current" }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first.map(PersistentWorkSessionMapper.snapshot(from:))
    }

    private static func makeDefaultContainer(requestedSyncMode: SyncMode) -> (
        container: ModelContainer,
        activeSyncMode: SyncMode
    ) {
        do {
            return (try makeContainer(inMemory: false, syncMode: requestedSyncMode), requestedSyncMode)
        } catch {
            logger.error("Requested SwiftData container failed: \(error.localizedDescription, privacy: .public)")
            if requestedSyncMode != .localOnly {
                do {
                    let container = try makeContainer(inMemory: false, syncMode: .localOnly)
                    logger.error("Falling back to persistent local SwiftData after CloudKit container failure.")
                    return (container, .localOnly)
                } catch {
                    logger.error("Persistent local SwiftData fallback failed: \(error.localizedDescription, privacy: .public)")
                }
            }
            logger.error("Falling back to in-memory local SwiftData.")
            return (try! makeContainer(inMemory: true, syncMode: .localOnly), .localOnly)
        }
    }

    private static func makeContainer(inMemory: Bool, syncMode: SyncMode) throws -> ModelContainer {
        let schema = Schema([
            PersistentWorkSession.self,
            PersistentCartBinding.self,
            PersistentRoomSelection.self,
            PersistentCart.self,
            PersistentCartConsumable.self,
            PersistentRoom.self,
            PersistentMediaAttachment.self,
            PersistentHistoryEntry.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: cloudKitDatabase(for: syncMode, inMemory: inMemory)
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func cloudKitDatabase(
        for syncMode: SyncMode,
        inMemory: Bool
    ) -> ModelConfiguration.CloudKitDatabase {
        guard !inMemory else { return .none }
        switch syncMode {
        case .localOnly:
            return .none
        case .privateCloudKit(let containerIdentifier):
            return .private(containerIdentifier)
        }
    }
}

private final class SwiftDataWorkSessionWriter: @unchecked Sendable {
    private let logger = Logger(
        subsystem: "com.alex.oceankey.swift",
        category: "SwiftDataWorkSessionWriter"
    )
    private let queue = DispatchQueue(label: "com.alex.oceankey.swift.swiftdata-writer", qos: .utility)
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func save(_ snapshot: WorkSessionSnapshot) {
        queue.async { [self, snapshot] in
            do {
                let context = ModelContext(container)
                try PersistentWorkSessionMapper.upsert(snapshot: snapshot, in: context)
                try context.save()
            } catch {
                logger.error("SwiftData save failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
