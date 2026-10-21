import Foundation
import OSLog

public struct BrooklynWebTelemetryReport: Codable, Equatable, Sendable {
    public let activeDurationMS: Double?
    public let activeSegmentCount: Int?
    public let actualMaxCadenceHz: Double?
    public let durationMS: Double?
    public let endedVisibilityState: String?
    public let frameCount: Int
    public let legacyRAFActiveIntervalCount: Int?
    public let legacyRAFBurstCount: Int?
    public let legacyRAFCadenceHz: Double?
    public let legacyRAFEffectiveCadenceHz: Double?
    public let legacyRAFMaximumMS: Double?
    public let legacyRAFMedianMS: Double?
    public let legacyRAFMissedSlotCount: Int?
    public let legacyRAFMissedSlotThresholdMS: Double?
    public let legacyRAFObservedActiveMS: Double?
    public let legacyRAFP99MS: Double?
    public let legacyRAFSampleCount: Int?
    public let legacyRAFStallCount: Int?
    public let legacyRAFStallThresholdMS: Double?
    public let manualAdvanceActiveIntervalCount: Int?
    public let manualAdvanceBurstCount: Int?
    public let manualAdvanceEffectiveCadenceHz: Double?
    public let manualAdvanceMaximumMS: Double?
    public let manualAdvanceMedianMS: Double?
    public let manualAdvanceMissedSlotCount: Int?
    public let manualAdvanceMissedSlotThresholdMS: Double?
    public let manualAdvanceObservedActiveMS: Double?
    public let manualAdvanceP99MS: Double?
    public let manualAdvanceStallCount: Int?
    public let manualAdvanceStallThresholdMS: Double?
    public let manualRenderCadenceHz: Double?
    public let manualRenderMedianMS: Double?
    public let manualRenderSampleCount: Int?
    public let manualSchedulerDroppedSlots: Int?
    public let maximumMS: Double?
    public let medianCadenceHz: Double?
    public let medianMS: Double?
    public let nativeDisplayLinkActiveDurationMS: Double?
    public let nativeDisplayLinkActiveIntervalCount: Int?
    public let nativeDisplayLinkActivityTransitions: Int?
    public let nativeDisplayLinkBurstCount: Int?
    public let nativeDisplayLinkCadenceHz: Double?
    public let nativeDisplayLinkEffectiveCadenceHz: Double?
    public let nativeDisplayLinkMaximumMS: Double?
    public let nativeDisplayLinkMedianMS: Double?
    public let nativeDisplayLinkMissedSlotCount: Int?
    public let nativeDisplayLinkMissedSlotThresholdMS: Double?
    public let nativeDisplayLinkObservedActiveMS: Double?
    public let nativeDisplayLinkP99MS: Double?
    public let nativeDisplayLinkRunLoopMode: String?
    public let nativeDisplayLinkSampleCount: Int?
    public let nativeDisplayLinkStallCount: Int?
    public let nativeDisplayLinkStallThresholdMS: Double?
    public let nativeDisplayLinkSuspensionDurationMS: Double?
    public let nativeDisplayLinkSuspensionGaps: Int?
    public let p99MS: Double?
    public let presentationMeasured: Bool?
    public let requestedDurationMS: Int
    public let sampleCount: Int
    public let sceneGridDrawCalls: Int?
    public let sceneInstanceCount: Int?
    public let stallThresholdMS: Double?
    public let stalls: Int
    public let startedVisibilityState: String?
    public let suspendedDurationMS: Double?
    public let suspensionCount: Int?
    public let suspensionReasons: [String]?
    public let transformMotionActiveIntervalCount: Int?
    public let transformMotionBurstCount: Int?
    public let transformMotionCadenceHz: Double?
    public let transformMotionEffectiveCadenceHz: Double?
    public let transformMotionMaximumMS: Double?
    public let transformMotionMedianMS: Double?
    public let transformMotionMissedSlotCount: Int?
    public let transformMotionMissedSlotThresholdMS: Double?
    public let transformMotionObservedActiveMS: Double?
    public let transformMotionP99MS: Double?
    public let transformMotionSampleCount: Int?
    public let transformMotionStallCount: Int?
    public let transformMotionStallThresholdMS: Double?
    public let version: Int
    public let visibilityState: String
    public let wallDurationMS: Double?
}

public enum BrooklynWebTelemetryRequest {
    public static func durationMS(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Int? {
        #if DEBUG
        guard environment["BROOKLYN_WEB_PERFORMANCE_SWEEP"] == "1" else {
            return nil
        }
        let requestedSeconds = environment["BROOKLYN_WEB_TELEMETRY_SECONDS"]
            .flatMap(Double.init) ?? 30
        return Int((min(60, max(1, requestedSeconds)) * 1_000).rounded())
        #else
        return nil
        #endif
    }
}

public enum BrooklynWebTelemetryStore {
    public static let latestReportFilename = "latest-telemetry.json"
    public static let userDefaultsKey = "BrooklynWebBackgroundKit.latestTelemetry"
    public static let didUpdateNotification = Notification.Name(
        "BrooklynWebBackgroundKit.telemetryDidUpdate"
    )

    private static let logger = Logger(
        subsystem: "BrooklynWebBackgroundKit",
        category: "Telemetry"
    )

    public static func decode(messageBody: Any) throws -> BrooklynWebTelemetryReport {
        guard JSONSerialization.isValidJSONObject(messageBody) else {
            throw TelemetryError.invalidMessage
        }
        let data = try JSONSerialization.data(
            withJSONObject: messageBody,
            options: [.sortedKeys]
        )
        return try JSONDecoder().decode(BrooklynWebTelemetryReport.self, from: data)
    }

    @discardableResult
    public static func persist(
        _ report: BrooklynWebTelemetryReport,
        directory: URL? = nil,
        userDefaults: UserDefaults = .standard
    ) throws -> URL {
        let data = try encoded(report)
        let directory = try directory ?? defaultDirectory()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let destination = directory.appendingPathComponent(
            latestReportFilename,
            isDirectory: false
        )
        try data.write(to: destination, options: [.atomic])
        userDefaults.set(data, forKey: userDefaultsKey)

        let line = Data("BROOKLYN_WEB_PERF ".utf8) + data + Data("\n".utf8)
        try? FileHandle.standardOutput.write(contentsOf: line)
        logger.info("BROOKLYN_WEB_PERF \(String(decoding: data, as: UTF8.self), privacy: .public)")
        NotificationCenter.default.post(
            name: didUpdateNotification,
            object: report
        )
        return destination
    }

    public static func load(from directory: URL? = nil) throws -> BrooklynWebTelemetryReport {
        let directory = try directory ?? defaultDirectory()
        let data = try Data(
            contentsOf: directory.appendingPathComponent(latestReportFilename)
        )
        return try JSONDecoder().decode(BrooklynWebTelemetryReport.self, from: data)
    }

    private static func encoded(_ report: BrooklynWebTelemetryReport) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(report)
    }

    private static func defaultDirectory() throws -> URL {
        try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appendingPathComponent("BrooklynWebBackgroundKit", isDirectory: true)
    }

    enum TelemetryError: Error {
        case invalidMessage
    }
}
