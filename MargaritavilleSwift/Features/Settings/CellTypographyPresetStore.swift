import Foundation

struct SavedCellTypographyPreset: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let savedAt: Date
    let typography: RoomCellTypography

    init(typography: RoomCellTypography, savedAt: Date) {
        schemaVersion = Self.currentSchemaVersion
        self.savedAt = savedAt
        self.typography = typography
    }
}

struct CellTypographyPresetStore {
    static let storageKey = "developer.cellTypography.savedPreset.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> SavedCellTypographyPreset? {
        guard let data = defaults.data(forKey: Self.storageKey) else { return nil }
        return try? Self.decoder.decode(SavedCellTypographyPreset.self, from: data)
    }

    @discardableResult
    func save(_ typography: RoomCellTypography, at date: Date = Date()) throws -> SavedCellTypographyPreset {
        let preset = SavedCellTypographyPreset(typography: typography, savedAt: date)
        defaults.set(try Self.encoder.encode(preset), forKey: Self.storageKey)
        return preset
    }

    func delete() {
        defaults.removeObject(forKey: Self.storageKey)
    }

    static func exportJSON(_ preset: SavedCellTypographyPreset) throws -> String {
        guard let json = String(data: try encoder.encode(preset), encoding: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return json
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
