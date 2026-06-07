import Foundation

struct LocalWorkSessionRepository: WorkSessionRepository, @unchecked Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        let supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appDirectory = supportDirectory.appendingPathComponent("OceanKeySwift", isDirectory: true)
        fileURL = appDirectory.appendingPathComponent("work-session.json")

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadSnapshot() throws -> WorkSessionSnapshot? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        if let snapshot = try? decoder.decode(WorkSessionSnapshot.self, from: data) {
            return snapshot
        }
        let legacyCarts = try decoder.decode([CartSection].self, from: data)
        return WorkSessionSnapshot(
            selection: WorkSessionStore.selectionState(from: legacyCarts),
            carts: legacyCarts
        )
    }

    func save(snapshot: WorkSessionSnapshot) {
        try? saveLegacySnapshot(snapshot)
    }

    func saveLegacySnapshot(_ snapshot: WorkSessionSnapshot) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let data = try encoder.encode(snapshot)
        let temporaryURL = directoryURL.appendingPathComponent(UUID().uuidString)
        try data.write(to: temporaryURL, options: [.atomic])

        if FileManager.default.fileExists(atPath: fileURL.path) {
            _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: temporaryURL)
        } else {
            try FileManager.default.moveItem(at: temporaryURL, to: fileURL)
        }
    }
}
