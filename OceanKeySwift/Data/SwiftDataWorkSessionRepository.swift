import Foundation
import OSLog
import SwiftData

final class SwiftDataWorkSessionRepository: WorkSessionRepository, @unchecked Sendable {
    enum SyncMode: Equatable, Sendable {
        case localOnly
        case privateCloudKit(containerIdentifier: String)
    }

    private static let logger = Logger(
        subsystem: "com.alex.margaritaville.swift",
        category: "SwiftDataWorkSessionRepository"
    )

    private let container: ModelContainer
    private let writer: SwiftDataWorkSessionWriter
    private let legacyRepository: LocalWorkSessionRepository?
    let syncMode: SyncMode
    let activeSyncMode: SyncMode
    let hotelID: String

    init(
        hotelID: String = HotelProfile.current.id,
        syncMode: SyncMode = .localOnly,
        storeDirectory: URL? = nil,
        container: ModelContainer? = nil,
        activeSyncMode: SyncMode? = nil,
        legacyRepository: LocalWorkSessionRepository? = LocalWorkSessionRepository()
    ) {
        self.hotelID = hotelID
        self.syncMode = syncMode
        if let container {
            self.container = container
            self.activeSyncMode = activeSyncMode ?? syncMode
        } else {
            let resolved = SwiftDataWorkSessionRepository.makeDefaultContainer(
                requestedSyncMode: syncMode,
                hotelID: hotelID,
                storeDirectory: storeDirectory
            )
            self.container = resolved.container
            self.activeSyncMode = resolved.activeSyncMode
        }
        self.writer = SwiftDataWorkSessionWriter(container: self.container)
        self.legacyRepository = legacyRepository
    }

    convenience init(
        hotelID: String = HotelProfile.current.id,
        inMemory: Bool,
        syncMode: SyncMode = .localOnly
    ) throws {
        let container = try SwiftDataWorkSessionRepository.makeContainer(
            inMemory: inMemory,
            syncMode: syncMode,
            hotelID: hotelID
        )
        self.init(
            hotelID: hotelID,
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

    private static func makeDefaultContainer(
        requestedSyncMode: SyncMode,
        hotelID: String,
        storeDirectory: URL?
    ) -> (
        container: ModelContainer,
        activeSyncMode: SyncMode
    ) {
        do {
            return (
                try makeContainer(
                    inMemory: false,
                    syncMode: requestedSyncMode,
                    hotelID: hotelID,
                    storeDirectory: storeDirectory
                ),
                requestedSyncMode
            )
        } catch {
            logger.error("Requested SwiftData container failed: \(error.localizedDescription, privacy: .public)")
            if requestedSyncMode != .localOnly {
                do {
                    let container = try makeContainer(
                        inMemory: false,
                        syncMode: .localOnly,
                        hotelID: hotelID,
                        storeDirectory: storeDirectory
                    )
                    logger.error("Falling back to persistent local SwiftData after CloudKit container failure.")
                    return (container, .localOnly)
                } catch {
                    logger.error("Persistent local SwiftData fallback failed: \(error.localizedDescription, privacy: .public)")
                }
            }
            logger.error("Falling back to in-memory local SwiftData.")
            do {
                return (
                    try makeContainer(
                        inMemory: true,
                        syncMode: .localOnly,
                        hotelID: hotelID,
                        storeDirectory: storeDirectory
                    ),
                    .localOnly
                )
            } catch {
                preconditionFailure("Unable to create any SwiftData work-session store: \(error.localizedDescription)")
            }
        }
    }

    private static func makeContainer(
        inMemory: Bool,
        syncMode: SyncMode,
        hotelID: String = HotelProfile.current.id,
        storeDirectory: URL? = nil
    ) throws -> ModelContainer {
        let schema = Schema([
            PersistentWorkSession.self,
            PersistentCartBinding.self,
            PersistentRoomSelection.self,
            PersistentCatalogOverride.self,
            PersistentCart.self,
            PersistentCartConsumable.self,
            PersistentRoom.self,
            PersistentMediaAttachment.self,
            PersistentHistoryEntry.self
        ])
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
        } else {
            configuration = ModelConfiguration(
                schema: schema,
                url: try persistentStoreURL(hotelID: hotelID, storeDirectory: storeDirectory),
                cloudKitDatabase: cloudKitDatabase(for: syncMode, inMemory: false)
            )
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func persistentStoreURL(hotelID: String, storeDirectory: URL?) throws -> URL {
        let applicationSupportURL: URL
        if let storeDirectory {
            applicationSupportURL = storeDirectory
        } else if let defaultURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            applicationSupportURL = defaultURL
        } else {
            throw CocoaError(.fileNoSuchFile)
        }
        try FileManager.default.createDirectory(
            at: applicationSupportURL,
            withIntermediateDirectories: true
        )
        let storeURL = applicationSupportURL.appendingPathComponent("workSession-\(safeStoreID(hotelID)).store")
        if hotelID == HotelProfile.current.id {
            try migrateLegacyDefaultStoreIfNeeded(in: applicationSupportURL, to: storeURL)
        }
        return storeURL
    }

    private static func safeStoreID(_ hotelID: String) -> String {
        hotelID
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }

    private static func migrateLegacyDefaultStoreIfNeeded(in directory: URL, to storeURL: URL) throws {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: storeURL.path) else { return }
        let legacyURL = directory.appendingPathComponent("default.store")
        guard fileManager.fileExists(atPath: legacyURL.path) else { return }
        for suffix in ["", "-shm", "-wal"] {
            let source = URL(fileURLWithPath: legacyURL.path + suffix)
            let destination = URL(fileURLWithPath: storeURL.path + suffix)
            guard fileManager.fileExists(atPath: source.path),
                  !fileManager.fileExists(atPath: destination.path)
            else { continue }
            try fileManager.copyItem(at: source, to: destination)
        }
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
        subsystem: "com.alex.margaritaville.swift",
        category: "SwiftDataWorkSessionWriter"
    )
    private let queue = DispatchQueue(label: "com.alex.margaritaville.swift.swiftdata-writer", qos: .utility)
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
