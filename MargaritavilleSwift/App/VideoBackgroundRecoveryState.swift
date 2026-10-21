import Foundation

enum VideoBackgroundPlaybackHealth: Equatable, Sendable {
    case healthy
    case renderPipelineLost
}

enum VideoBackgroundLifecycleEvent: Equatable, Sendable {
    case sceneActive
    case sceneInactive
    case interruptionBegan
    case interruptionEnded
    case mediaServicesWereReset
    case playbackStalled
    case captureOwnershipChanged(isActive: Bool)
    case renderedFrame
}

enum VideoBackgroundRecoveryAction: Equatable, Sendable {
    case none
    case pause
    case resume
    case rebuild(generation: Int)
}

struct VideoBackgroundRecoveryState: Equatable, Sendable {
    private(set) var sceneIsActive = false
    private(set) var interruptionIsActive = false
    private(set) var captureOwnerIsActive = false
    private(set) var recoveryGeneration = 0
    private(set) var pendingRecoveryGeneration: Int?
    private(set) var rebuildIssuedGeneration: Int?
    private var forcedRebuildGeneration: Int?
    private var awaitingRenderedFrame = false

    var canPlay: Bool {
        sceneIsActive && !interruptionIsActive && !captureOwnerIsActive
    }

    mutating func transition(
        _ event: VideoBackgroundLifecycleEvent,
        health: VideoBackgroundPlaybackHealth
    ) -> VideoBackgroundRecoveryAction {
        switch event {
        case .sceneActive:
            guard !sceneIsActive else { return .none }
            sceneIsActive = true
            return recoveryAction(health: health)

        case .sceneInactive:
            guard sceneIsActive else { return .none }
            sceneIsActive = false
            return .pause

        case .interruptionBegan:
            guard !interruptionIsActive else { return .none }
            interruptionIsActive = true
            beginRecoveryGeneration()
            return .pause

        case .interruptionEnded:
            guard interruptionIsActive else { return .none }
            interruptionIsActive = false
            return recoveryAction(health: health)

        case .mediaServicesWereReset:
            let generation = ensureRecoveryGeneration()
            forcedRebuildGeneration = generation
            return recoveryAction(health: .renderPipelineLost)

        case .playbackStalled:
            let generation = ensureRecoveryGeneration()
            forcedRebuildGeneration = generation
            return recoveryAction(health: .renderPipelineLost)

        case .captureOwnershipChanged(let isActive):
            guard captureOwnerIsActive != isActive else { return .none }
            captureOwnerIsActive = isActive
            if isActive {
                return pendingRecoveryGeneration == nil ? .none : .pause
            }
            return recoveryAction(health: health)

        case .renderedFrame:
            guard awaitingRenderedFrame || pendingRecoveryGeneration != nil else { return .none }
            pendingRecoveryGeneration = nil
            forcedRebuildGeneration = nil
            awaitingRenderedFrame = false
            return .none
        }
    }

    private mutating func beginRecoveryGeneration() {
        recoveryGeneration += 1
        pendingRecoveryGeneration = recoveryGeneration
        forcedRebuildGeneration = nil
        awaitingRenderedFrame = false
    }

    private mutating func ensureRecoveryGeneration() -> Int {
        if let pendingRecoveryGeneration {
            return pendingRecoveryGeneration
        }
        beginRecoveryGeneration()
        return recoveryGeneration
    }

    private mutating func recoveryAction(
        health: VideoBackgroundPlaybackHealth
    ) -> VideoBackgroundRecoveryAction {
        guard canPlay else { return .none }
        if pendingRecoveryGeneration == nil, health == .renderPipelineLost {
            let generation = ensureRecoveryGeneration()
            forcedRebuildGeneration = generation
        }
        guard let generation = pendingRecoveryGeneration else { return .resume }

        let mustRebuild = health == .renderPipelineLost || forcedRebuildGeneration == generation
        if mustRebuild {
            guard rebuildIssuedGeneration != generation else { return .none }
            rebuildIssuedGeneration = generation
            awaitingRenderedFrame = true
            return .rebuild(generation: generation)
        }

        awaitingRenderedFrame = true
        return .resume
    }
}

@MainActor
final class AudioCaptureActivityMonitor {
    static let shared = AudioCaptureActivityMonitor()
    static let activityDidChangeNotification = Notification.Name(
        "com.alex.margaritaville.swift.audioCaptureActivityDidChange"
    )

    private var owners: Set<UUID> = []

    var isCaptureActive: Bool {
        !owners.isEmpty
    }

    func begin(ownerID: UUID) {
        let wasActive = isCaptureActive
        owners.insert(ownerID)
        postChangeIfNeeded(wasActive: wasActive)
    }

    func end(ownerID: UUID) {
        let wasActive = isCaptureActive
        owners.remove(ownerID)
        postChangeIfNeeded(wasActive: wasActive)
    }

    private func postChangeIfNeeded(wasActive: Bool) {
        guard wasActive != isCaptureActive else { return }
        NotificationCenter.default.post(name: Self.activityDidChangeNotification, object: self)
    }
}
