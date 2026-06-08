import AVFoundation
import OSLog
import SwiftUI
import UIKit

struct InteractionFeedbackClient: Sendable {
    let tap: @MainActor @Sendable () -> Void
    let confirm: @MainActor @Sendable () -> Void
    let longPress: @MainActor @Sendable () -> Void
    let holdStart: @MainActor @Sendable () -> Void
    let holdWarning: @MainActor @Sendable () -> Void
    let holdCommit: @MainActor @Sendable () -> Void
    let select: @MainActor @Sendable () -> Void
    let deselect: @MainActor @Sendable () -> Void
    let invalid: @MainActor @Sendable () -> Void

    static let noop = InteractionFeedbackClient(
        tap: {},
        confirm: {},
        longPress: {},
        holdStart: {},
        holdWarning: {},
        holdCommit: {},
        select: {},
        deselect: {},
        invalid: {}
    )

    static func live(
        _ service: InteractionFeedbackService,
        soundPackV2: Bool = false,
        hapticsV2: Bool = false
    ) -> InteractionFeedbackClient {
        InteractionFeedbackClient(
            tap: { service.tap(soundPackV2: soundPackV2, hapticsV2: hapticsV2) },
            confirm: { service.confirm(soundPackV2: soundPackV2, hapticsV2: hapticsV2) },
            longPress: { service.longPress(soundPackV2: soundPackV2, hapticsV2: hapticsV2) },
            holdStart: { service.holdStart(hapticsV2: hapticsV2) },
            holdWarning: { service.holdWarning(hapticsV2: hapticsV2) },
            holdCommit: { service.holdCommit(soundPackV2: soundPackV2, hapticsV2: hapticsV2) },
            select: { service.select(soundPackV2: soundPackV2, hapticsV2: hapticsV2) },
            deselect: { service.deselect(soundPackV2: soundPackV2, hapticsV2: hapticsV2) },
            invalid: { service.invalid(soundPackV2: soundPackV2, hapticsV2: hapticsV2) }
        )
    }
}

@MainActor
final class InteractionFeedbackService {
    private let sounds = InteractionSoundPlayer()
    private let selection = UISelectionFeedbackGenerator()
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)

    func tap(soundPackV2: Bool = false, hapticsV2: Bool = false) {
        light.impactOccurred(intensity: hapticsV2 ? 0.42 : 0.55)
        if soundPackV2 {
            sounds.playTapAccent()
        }
        prepare()
    }

    func confirm(soundPackV2: Bool = false, hapticsV2: Bool = false) {
        medium.impactOccurred(intensity: hapticsV2 ? 0.96 : 0.82)
        sounds.playSelect(variant: soundPackV2 ? .confirm : .plain)
        prepare()
    }

    func longPress(soundPackV2: Bool = false, hapticsV2: Bool = false) {
        heavy.impactOccurred(intensity: hapticsV2 ? 1.0 : 0.9)
        if hapticsV2 {
            medium.impactOccurred(intensity: 0.45)
        }
        sounds.playSelect(variant: soundPackV2 ? .deep : .plain)
        prepare()
    }

    func holdStart(hapticsV2: Bool = false) {
        selection.selectionChanged()
        if hapticsV2 {
            light.impactOccurred(intensity: 0.25)
        }
        prepare()
    }

    func holdWarning(hapticsV2: Bool = false) {
        light.impactOccurred(intensity: hapticsV2 ? 0.95 : 0.7)
        prepare()
    }

    func holdCommit(soundPackV2: Bool = false, hapticsV2: Bool = false) {
        heavy.impactOccurred(intensity: hapticsV2 ? 1.0 : 0.92)
        sounds.playSelect(variant: soundPackV2 ? .commit : .plain)
        prepare()
    }

    func select(soundPackV2: Bool = false, hapticsV2: Bool = false) {
        medium.impactOccurred(intensity: hapticsV2 ? 0.86 : 0.72)
        sounds.playSelect(variant: soundPackV2 ? .select : .plain)
        prepare()
    }

    func deselect(soundPackV2: Bool = false, hapticsV2: Bool = false) {
        light.impactOccurred(intensity: hapticsV2 ? 0.36 : 0.48)
        sounds.playDeselect(variant: soundPackV2 ? .soft : .plain)
        prepare()
    }

    func invalid(soundPackV2: Bool = false, hapticsV2: Bool = false) {
        light.impactOccurred(intensity: hapticsV2 ? 0.18 : 0.3)
        sounds.playDeselect(variant: soundPackV2 ? .invalid : .plain)
        prepare()
    }

    private func prepare() {
        selection.prepare()
        light.prepare()
        medium.prepare()
        heavy.prepare()
    }
}

private final class InteractionSoundPlayer {
    private static let logger = Logger(subsystem: "com.alex.oceankey.swift", category: "InteractionSound")

    private var selectPlayer: AVAudioPlayer?
    private var deselectPlayer: AVAudioPlayer?

    enum SelectVariant {
        case plain
        case confirm
        case deep
        case commit
        case select
    }

    enum DeselectVariant {
        case plain
        case soft
        case invalid
    }

    init() {
        configureAudioSession()
        selectPlayer = makePlayer(resource: "pressed")
        deselectPlayer = makePlayer(resource: "click")
    }

    func playSelect(variant: SelectVariant = .plain) {
        switch variant {
        case .plain:
            play(selectPlayer, volume: 0.20, rate: 1.0, pan: 0)
        case .confirm:
            play(selectPlayer, volume: 0.24, rate: 1.12, pan: 0.05)
        case .deep:
            play(selectPlayer, volume: 0.23, rate: 0.82, pan: -0.08)
        case .commit:
            play(selectPlayer, volume: 0.28, rate: 1.24, pan: 0.10)
        case .select:
            play(selectPlayer, volume: 0.22, rate: 1.06, pan: -0.04)
        }
    }

    func playDeselect(variant: DeselectVariant = .plain) {
        switch variant {
        case .plain:
            play(deselectPlayer, volume: 0.20, rate: 1.0, pan: 0)
        case .soft:
            play(deselectPlayer, volume: 0.15, rate: 0.92, pan: -0.05)
        case .invalid:
            play(deselectPlayer, volume: 0.23, rate: 0.72, pan: 0.08)
        }
    }

    func playTapAccent() {
        play(deselectPlayer, volume: 0.11, rate: 1.36, pan: 0.03)
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
        } catch {
            Self.logger.error("Failed to configure interaction audio: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func makePlayer(resource: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "wav") else {
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.2
            player.enableRate = true
            player.prepareToPlay()
            return player
        } catch {
            Self.logger.error("Failed to load interaction sound \(resource, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func play(
        _ player: AVAudioPlayer?,
        volume: Float,
        rate: Float,
        pan: Float
    ) {
        guard let player else { return }
        if player.isPlaying {
            player.currentTime = 0
        }
        player.volume = volume
        player.rate = rate
        player.pan = pan
        player.play()
    }
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
