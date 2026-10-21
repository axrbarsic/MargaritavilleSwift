#if DEBUG
import Foundation
import OSLog
import UIKit

struct DebugKeepAwakePolicy: Equatable, Sendable {
    static let environmentKey = "MARGARITAVILLE_KEEP_SCREEN_AWAKE"

    let isRequested: Bool

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        isRequested = environment[Self.environmentKey] == "1"
    }

    func shouldDisableIdleTimer(isAppActive: Bool) -> Bool {
        isRequested && isAppActive
    }
}

struct DebugKeepAwakeState: Equatable, Sendable {
    let policy: DebugKeepAwakePolicy
    private(set) var appliedValue: Bool?

    init(policy: DebugKeepAwakePolicy) {
        self.policy = policy
    }

    mutating func transition(isAppActive: Bool) -> Bool? {
        apply(policy.shouldDisableIdleTimer(isAppActive: isAppActive))
    }

    mutating func reset() -> Bool? {
        apply(false)
    }

    private mutating func apply(_ nextValue: Bool) -> Bool? {
        guard appliedValue != nextValue else { return nil }
        appliedValue = nextValue
        return nextValue
    }
}

@MainActor
final class DebugKeepAwakeController {
    private static let logger = Logger(
        subsystem: "com.alex.margaritaville.swift",
        category: "KeepAwake"
    )

    private var state: DebugKeepAwakeState

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        state = DebugKeepAwakeState(
            policy: DebugKeepAwakePolicy(environment: environment)
        )
    }

    func update(isAppActive: Bool, reason: String) {
        let desiredValue = state.policy.shouldDisableIdleTimer(
            isAppActive: isAppActive
        )
        let transition = state.transition(isAppActive: isAppActive)
        guard transition != nil
            || UIApplication.shared.isIdleTimerDisabled != desiredValue
        else {
            return
        }
        apply(
            desiredValue,
            isAppActive: isAppActive,
            reason: reason
        )
    }

    func reset(reason: String) {
        let transition = state.reset()
        guard transition != nil || UIApplication.shared.isIdleTimerDisabled else {
            return
        }
        apply(false, isAppActive: false, reason: reason)
    }

    private func apply(
        _ shouldDisableIdleTimer: Bool,
        isAppActive: Bool,
        reason: String
    ) {
        UIApplication.shared.isIdleTimerDisabled = shouldDisableIdleTimer
        let readback = UIApplication.shared.isIdleTimerDisabled
        let line = [
            "MARGARITAVILLE_KEEP_SCREEN_AWAKE",
            "requested=\(state.policy.isRequested)",
            "appActive=\(isAppActive)",
            "activePolicy=\(shouldDisableIdleTimer)",
            "idleTimerDisabled=\(readback)",
            "reason=\(reason)"
        ].joined(separator: " ")

        if let data = "\(line)\n".data(using: .utf8) {
            try? FileHandle.standardOutput.write(contentsOf: data)
        }
        Self.logger.info("\(line, privacy: .public)")
    }

    deinit {
        MainActor.assumeIsolated {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}
#endif
