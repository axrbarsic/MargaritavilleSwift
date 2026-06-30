import SwiftUI
import UIKit

struct InteractionFeedbackClient: Sendable {
    let tap: @MainActor @Sendable () -> Void
    let confirm: @MainActor @Sendable () -> Void
    let longPress: @MainActor @Sendable () -> Void
    let holdStart: @MainActor @Sendable () -> Void
    let holdWarning: @MainActor @Sendable () -> Void
    let holdCommit: @MainActor @Sendable () -> Void
    let holdStartHapticOnly: @MainActor @Sendable () -> Void
    let holdWarningHapticOnly: @MainActor @Sendable () -> Void
    let holdCommitHapticOnly: @MainActor @Sendable () -> Void
    let select: @MainActor @Sendable () -> Void
    let deselect: @MainActor @Sendable () -> Void
    let invalid: @MainActor @Sendable () -> Void
    let detent: @MainActor @Sendable () -> Void
    let playEvent: @MainActor @Sendable (InteractionSoundEvent) -> Void
    let previewSound: @MainActor @Sendable (InteractionSoundAsset) -> Void

    static let noop = InteractionFeedbackClient(
        tap: {},
        confirm: {},
        longPress: {},
        holdStart: {},
        holdWarning: {},
        holdCommit: {},
        holdStartHapticOnly: {},
        holdWarningHapticOnly: {},
        holdCommitHapticOnly: {},
        select: {},
        deselect: {},
        invalid: {},
        detent: {},
        playEvent: { _ in },
        previewSound: { _ in }
    )

    static func live(
        _ service: InteractionFeedbackService,
        hapticsV2: Bool = false,
        soundAssignments: InteractionSoundAssignments = InteractionSoundAssignments()
    ) -> InteractionFeedbackClient {
        InteractionFeedbackClient(
            tap: deferred { service.tap(sound: soundAssignments.asset(for: .tap), hapticsV2: hapticsV2) },
            confirm: deferred { service.confirm(sound: soundAssignments.asset(for: .confirm), hapticsV2: hapticsV2) },
            longPress: deferred { service.longPress(sound: soundAssignments.asset(for: .longPress), hapticsV2: hapticsV2) },
            holdStart: deferred { service.holdStart(sound: soundAssignments.asset(for: .holdStart), hapticsV2: hapticsV2) },
            holdWarning: deferred { service.holdWarning(sound: soundAssignments.asset(for: .holdWarning), hapticsV2: hapticsV2) },
            holdCommit: deferred { service.holdCommit(sound: soundAssignments.asset(for: .holdCommit), hapticsV2: hapticsV2) },
            holdStartHapticOnly: deferred { service.holdStartHapticOnly(hapticsV2: hapticsV2) },
            holdWarningHapticOnly: deferred { service.holdWarningHapticOnly(hapticsV2: hapticsV2) },
            holdCommitHapticOnly: deferred { service.holdCommitHapticOnly(hapticsV2: hapticsV2) },
            select: deferred { service.select(sound: soundAssignments.asset(for: .select), hapticsV2: hapticsV2) },
            deselect: deferred { service.deselect(sound: soundAssignments.asset(for: .deselect), hapticsV2: hapticsV2) },
            invalid: deferred { service.invalid(sound: soundAssignments.asset(for: .invalid), hapticsV2: hapticsV2) },
            detent: deferred { service.detent(sound: soundAssignments.asset(for: .detent)) },
            playEvent: { event in
                deferred { service.playSound(soundAssignments.asset(for: event), priority: event.playbackPriority) }()
            },
            previewSound: { sound in
                deferred { service.previewSound(sound) }()
            }
        )
    }

    private static func deferred(
        _ action: @escaping @MainActor @Sendable () -> Void
    ) -> @MainActor @Sendable () -> Void {
        {
            action()
        }
    }
}

@MainActor
final class InteractionFeedbackService {
    private let sounds = InteractionSoundPlayer()
    private let selection = UISelectionFeedbackGenerator()
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private var prepareTask: Task<Void, Never>?
    private var soundFlushTask: Task<Void, Never>?
    private var queuedSound: QueuedInteractionSound?

    init() {
        prepare()
    }

    func tap(sound: InteractionSoundAsset = .legacyClick, hapticsV2: Bool = false) {
        light.impactOccurred(intensity: hapticsV2 ? 0.42 : 0.55)
        playSound(sound, priority: InteractionSoundEvent.tap.playbackPriority)
        schedulePrepare()
    }

    func confirm(sound: InteractionSoundAsset = .legacyPressed, hapticsV2: Bool = false) {
        medium.impactOccurred(intensity: hapticsV2 ? 0.96 : 0.82)
        if hapticsV2 {
            notification.notificationOccurred(.success)
        }
        playSound(sound, priority: InteractionSoundEvent.confirm.playbackPriority)
        schedulePrepare()
    }

    func longPress(sound: InteractionSoundAsset = .legacyPressed, hapticsV2: Bool = false) {
        heavy.impactOccurred(intensity: hapticsV2 ? 1.0 : 0.9)
        if hapticsV2 {
            medium.impactOccurred(intensity: 0.45)
        }
        playSound(sound, priority: InteractionSoundEvent.longPress.playbackPriority)
        schedulePrepare()
    }

    func holdStart(sound: InteractionSoundAsset = .none, hapticsV2: Bool = false) {
        performHoldStartHaptic(hapticsV2: hapticsV2)
        playSound(sound, priority: InteractionSoundEvent.holdStart.playbackPriority)
        schedulePrepare()
    }

    func holdWarning(sound: InteractionSoundAsset = .kenneyTick1, hapticsV2: Bool = false) {
        performHoldWarningHaptic(hapticsV2: hapticsV2)
        playSound(sound, priority: InteractionSoundEvent.holdWarning.playbackPriority)
        schedulePrepare()
    }

    func holdCommit(sound: InteractionSoundAsset = .legacyPressed, hapticsV2: Bool = false) {
        performHoldCommitHaptic(hapticsV2: hapticsV2)
        playSound(sound, priority: InteractionSoundEvent.holdCommit.playbackPriority)
        schedulePrepare()
    }

    func holdStartHapticOnly(hapticsV2: Bool = false) {
        performHoldStartHaptic(hapticsV2: hapticsV2)
        schedulePrepare()
    }

    func holdWarningHapticOnly(hapticsV2: Bool = false) {
        performHoldWarningHaptic(hapticsV2: hapticsV2)
        schedulePrepare()
    }

    func holdCommitHapticOnly(hapticsV2: Bool = false) {
        performHoldCommitHaptic(hapticsV2: hapticsV2)
        schedulePrepare()
    }

    func select(sound: InteractionSoundAsset = .legacyPressed, hapticsV2: Bool = false) {
        medium.impactOccurred(intensity: hapticsV2 ? 0.86 : 0.72)
        playSound(sound, priority: InteractionSoundEvent.select.playbackPriority)
        schedulePrepare()
    }

    func deselect(sound: InteractionSoundAsset = .legacyClick, hapticsV2: Bool = false) {
        light.impactOccurred(intensity: hapticsV2 ? 0.36 : 0.48)
        playSound(sound, priority: InteractionSoundEvent.deselect.playbackPriority)
        schedulePrepare()
    }

    func invalid(sound: InteractionSoundAsset = .legacyClick, hapticsV2: Bool = false) {
        light.impactOccurred(intensity: hapticsV2 ? 0.18 : 0.3)
        if hapticsV2 {
            notification.notificationOccurred(.error)
        }
        playSound(sound, priority: InteractionSoundEvent.invalid.playbackPriority)
        schedulePrepare()
    }

    func detent(sound: InteractionSoundAsset = .kenneyTick1) {
        selection.selectionChanged()
        light.impactOccurred(intensity: 0.62)
        playSound(sound, priority: InteractionSoundEvent.detent.playbackPriority)
        schedulePrepare()
    }

    func playSound(_ sound: InteractionSoundAsset, priority: Int) {
        queueSound(sound, priority: priority)
        schedulePrepare()
    }

    func previewSound(_ sound: InteractionSoundAsset) {
        soundFlushTask?.cancel()
        soundFlushTask = nil
        queuedSound = nil
        sounds.playEffect(sound)
        schedulePrepare()
    }

    func restoreAudioSession() {
        sounds.restoreAudioSession()
    }

    private func schedulePrepare() {
        guard prepareTask == nil else { return }
        prepareTask = Task { @MainActor [weak self] in
            await Task.yield()
            self?.prepareTask = nil
            self?.prepare()
        }
    }

    private func prepare() {
        selection.prepare()
        light.prepare()
        medium.prepare()
        heavy.prepare()
        notification.prepare()
    }

    private func performHoldStartHaptic(hapticsV2: Bool) {
        selection.selectionChanged()
        if hapticsV2 {
            light.impactOccurred(intensity: 0.25)
        }
    }

    private func performHoldWarningHaptic(hapticsV2: Bool) {
        light.impactOccurred(intensity: hapticsV2 ? 0.95 : 0.7)
        if hapticsV2 {
            notification.notificationOccurred(.warning)
        }
    }

    private func performHoldCommitHaptic(hapticsV2: Bool) {
        heavy.impactOccurred(intensity: hapticsV2 ? 1.0 : 0.92)
        if hapticsV2 {
            notification.notificationOccurred(.success)
        }
    }

    private func queueSound(_ sound: InteractionSoundAsset, priority: Int) {
        guard sound != .none else { return }
        let nextSound = QueuedInteractionSound(sound: sound, priority: priority)
        if let queuedSound,
           queuedSound.priority > nextSound.priority {
            return
        }
        queuedSound = nextSound
        guard soundFlushTask == nil else { return }
        soundFlushTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(45))
            self?.flushQueuedSound()
        }
    }

    private func flushQueuedSound() {
        soundFlushTask = nil
        guard let queuedSound else { return }
        self.queuedSound = nil
        sounds.playEffect(queuedSound.sound)
    }
}

private struct QueuedInteractionSound {
    let sound: InteractionSoundAsset
    let priority: Int
}


private struct InteractionFeedbackEnvironmentKey: EnvironmentKey {
    static let defaultValue = InteractionFeedbackClient.noop
}

extension EnvironmentValues {
    var interactionFeedback: InteractionFeedbackClient {
        get { self[InteractionFeedbackEnvironmentKey.self] }
        set { self[InteractionFeedbackEnvironmentKey.self] = newValue }
    }
}
