import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let margaritavillePresetBackup = UTType(exportedAs: AppIdentity.presetBackupTypeIdentifier)
}

struct MargaritavillePresetBackupPayload: Codable, Equatable, Sendable {
    struct Background: Codable, Equatable, Sendable {
        var mode: AppBackgroundMode
        var matrixSpeed: Double
        var tvStaticVariant: TVStaticNoiseVariant
        var tvStaticSpeed: Double
        var tvStaticParticleSize: Double
        var tvStaticBrightness: Double
        var tvStaticGreenTint: Double
        var videoRelativePath: String?
        var videoFilename: String?
        var videoBlur: Double
        var videoBrightness: Double
        var videoGreenTint: Double
        var videoGridIntensity: Double
    }

    var schemaVersion: Int
    var exportedAt: Date
    var appVersion: String
    var presets: [AIVisualPreset]
    var background: Background

    static func make(
        presets: [AIVisualPreset],
        appSettings: AppSettingsStore,
        exportedAt: Date = Date()
    ) -> MargaritavillePresetBackupPayload {
        MargaritavillePresetBackupPayload(
            schemaVersion: 1,
            exportedAt: exportedAt,
            appVersion: AppBuildInfo.versionLabel,
            presets: presets,
            background: Background(
                mode: appSettings.appBackgroundMode,
                matrixSpeed: appSettings.matrixSpeed,
                tvStaticVariant: appSettings.tvStaticVariant,
                tvStaticSpeed: appSettings.tvStaticSpeed,
                tvStaticParticleSize: appSettings.tvStaticParticleSize,
                tvStaticBrightness: appSettings.tvStaticBrightness,
                tvStaticGreenTint: appSettings.tvStaticGreenTint,
                videoRelativePath: appSettings.backgroundVideoRelativePath,
                videoFilename: appSettings.backgroundVideoRelativePath.map { URL(fileURLWithPath: $0).lastPathComponent },
                videoBlur: appSettings.backgroundVideoBlur,
                videoBrightness: appSettings.backgroundVideoBrightness,
                videoGreenTint: appSettings.backgroundVideoGreenTint,
                videoGridIntensity: appSettings.backgroundVideoGridIntensity
            )
        )
    }
}

struct MargaritavillePresetBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.margaritavillePresetBackup, .json] }

    var payload: MargaritavillePresetBackupPayload

    init(payload: MargaritavillePresetBackupPayload) {
        self.payload = payload
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        payload = try Self.decoder.decode(MargaritavillePresetBackupPayload.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try Self.encoder.encode(payload))
    }

    static func filename(exportedAt: Date = Date()) -> String {
        "\(AppIdentity.presetBackupFilenamePrefix)-\(Self.filenameFormatter.string(from: exportedAt))"
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private static let filenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}
