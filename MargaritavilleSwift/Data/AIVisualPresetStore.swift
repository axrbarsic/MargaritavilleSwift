import Foundation
import SwiftData

struct AIVisualPreset: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var title: String
    var summary: String
    var kind: AIVisualPresetKind
    var payload: AIVisualPresetPayload
    var modelTier: DeepSeekModelTier
    var prompt: String
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
}

@MainActor
@Observable
final class AIVisualPresetStore {
    enum StorageMode: Equatable, Sendable {
        case cloudKit(containerIdentifier: String)
        case localFallback(reason: String)
        case memoryOnly

        var isAppleSynced: Bool {
            if case .cloudKit = self { return true }
            return false
        }

        var statusTitle: String {
            switch self {
            case .cloudKit:
                return "Apple sync включён"
            case .localFallback:
                return "Apple sync недоступен"
            case .memoryOnly:
                return "Тестовый режим"
            }
        }

        var statusDetails: String {
            switch self {
            case .cloudKit(let containerIdentifier):
                return "Пресеты сохраняются в SwiftData store с CloudKit private database: \(containerIdentifier)."
            case .localFallback(let reason):
                return "Пресеты не будут надёжно перенесены на другое устройство, пока CloudKit не поднят. Причина: \(reason)"
            case .memoryOnly:
                return "Временный in-memory store используется только для preview/test."
            }
        }
    }

    private let container: ModelContainer?
    let storageMode: StorageMode
    private(set) var presets: [AIVisualPreset] = []
    private(set) var lastError: String?

    init(container: ModelContainer, storageMode: StorageMode) {
        self.container = container
        self.storageMode = storageMode
    }

    private init(storageMode: StorageMode, lastError: String) {
        self.container = nil
        self.storageMode = storageMode
        self.lastError = lastError
    }

    convenience init(inMemory: Bool = false, storeDirectory: URL? = nil) throws {
        let schema = Schema([PersistentAIVisualPreset.self])
        let configuration: ModelConfiguration
        let storageMode: StorageMode
        if inMemory {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            storageMode = .memoryOnly
        } else {
            configuration = ModelConfiguration(
                schema: schema,
                url: try Self.persistentStoreURL(storeDirectory: storeDirectory),
                cloudKitDatabase: .private(AppleSyncConfiguration.containerIdentifier)
            )
            storageMode = .cloudKit(containerIdentifier: AppleSyncConfiguration.containerIdentifier)
        }
        try self.init(
            container: ModelContainer(for: schema, configurations: [configuration]),
            storageMode: storageMode
        )
    }

    convenience init(localFallbackReason reason: String, storeDirectory: URL? = nil) throws {
        let schema = Schema([PersistentAIVisualPreset.self])
        let configuration = ModelConfiguration(
            schema: schema,
            url: try Self.persistentStoreURL(storeDirectory: storeDirectory),
            cloudKitDatabase: .none
        )
        try self.init(
            container: ModelContainer(for: schema, configurations: [configuration]),
            storageMode: .localFallback(reason: reason)
        )
    }

    func load() {
        guard let container else {
            presets = []
            lastError = lastError ?? "SwiftData store недоступен."
            return
        }
        do {
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<PersistentAIVisualPreset>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            presets = try context.fetch(descriptor).compactMap(Self.map)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func save(draft: AIVisualPresetDraft, modelTier: DeepSeekModelTier, prompt: String) {
        guard let container else {
            lastError = "SwiftData store недоступен, пресет не сохранён."
            return
        }
        do {
            let now = Date()
            let context = ModelContext(container)
            let record = PersistentAIVisualPreset(
                title: draft.title,
                summary: draft.summary,
                kindRawValue: draft.kind.rawValue,
                payloadData: try JSONEncoder().encode(draft.payload),
                modelTierRawValue: modelTier.rawValue,
                prompt: prompt,
                isFavorite: true,
                createdAt: now,
                updatedAt: now
            )
            context.insert(record)
            try context.save()
            load()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func delete(_ preset: AIVisualPreset) {
        guard let container else {
            lastError = "SwiftData store недоступен, удалить пресет невозможно."
            return
        }
        do {
            let context = ModelContext(container)
            let id = preset.id
            let descriptor = FetchDescriptor<PersistentAIVisualPreset>(
                predicate: #Predicate { $0.id == id }
            )
            for record in try context.fetch(descriptor) {
                context.delete(record)
            }
            try context.save()
            load()
        } catch {
            lastError = error.localizedDescription
        }
    }

    private static func map(_ record: PersistentAIVisualPreset) -> AIVisualPreset? {
        guard let kind = AIVisualPresetKind(rawValue: record.kindRawValue),
              let modelTier = DeepSeekModelTier(rawValue: record.modelTierRawValue),
              let payload = try? JSONDecoder().decode(AIVisualPresetPayload.self, from: record.payloadData)
        else {
            return nil
        }
        return AIVisualPreset(
            id: record.id,
            title: record.title,
            summary: record.summary,
            kind: kind,
            payload: payload,
            modelTier: modelTier,
            prompt: record.prompt,
            isFavorite: record.isFavorite,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }

    private static func persistentStoreURL(storeDirectory: URL? = nil) throws -> URL {
        let applicationSupportURL = storeDirectory ?? AppStorageDirectory.applicationSupportSubdirectory()
        try FileManager.default.createDirectory(
            at: applicationSupportURL,
            withIntermediateDirectories: true
        )
        return applicationSupportURL.appendingPathComponent("ai-visual-presets.store")
    }

    static func emptyMemoryOnly(lastError: String) -> AIVisualPresetStore {
        AIVisualPresetStore(storageMode: .memoryOnly, lastError: lastError)
    }
}
