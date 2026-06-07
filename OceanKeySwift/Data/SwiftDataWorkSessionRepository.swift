import Foundation
import OSLog
import SwiftData

final class SwiftDataWorkSessionRepository: WorkSessionRepository, @unchecked Sendable {
    enum SyncMode: Sendable {
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

    init(
        container: ModelContainer = SwiftDataWorkSessionRepository.makeDefaultContainer(),
        legacyRepository: LocalWorkSessionRepository? = LocalWorkSessionRepository()
    ) {
        self.container = container
        self.writer = SwiftDataWorkSessionWriter(container: container)
        self.legacyRepository = legacyRepository
    }

    convenience init(inMemory: Bool) throws {
        let container = try SwiftDataWorkSessionRepository.makeContainer(inMemory: inMemory)
        self.init(container: container, legacyRepository: nil)
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

    private static func makeDefaultContainer() -> ModelContainer {
        do {
            return try makeContainer(inMemory: false)
        } catch {
            logger.error("Persistent SwiftData container failed, falling back to memory: \(error.localizedDescription, privacy: .public)")
            return try! makeContainer(inMemory: true)
        }
    }

    private static func makeContainer(inMemory: Bool) throws -> ModelContainer {
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
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
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
