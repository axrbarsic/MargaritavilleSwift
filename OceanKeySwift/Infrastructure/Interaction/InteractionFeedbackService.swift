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

    static func live(_ service: InteractionFeedbackService) -> InteractionFeedbackClient {
        InteractionFeedbackClient(
            tap: { service.tap() },
            confirm: { service.confirm() },
            longPress: { service.longPress() },
            holdStart: { service.holdStart() },
            holdWarning: { service.holdWarning() },
            holdCommit: { service.holdCommit() },
            select: { service.select() },
            deselect: { service.deselect() },
            invalid: { service.invalid() }
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

    func tap() {
        light.impactOccurred(intensity: 0.55)
        prepare()
    }

    func confirm() {
        medium.impactOccurred(intensity: 0.82)
        sounds.playSelect()
        prepare()
    }

    func longPress() {
        heavy.impactOccurred(intensity: 0.9)
        sounds.playSelect()
        prepare()
    }

    func holdStart() {
        selection.selectionChanged()
        prepare()
    }

    func holdWarning() {
        light.impactOccurred(intensity: 0.7)
        prepare()
    }

    func holdCommit() {
        heavy.impactOccurred(intensity: 0.92)
        sounds.playSelect()
        prepare()
    }

    func select() {
        medium.impactOccurred(intensity: 0.72)
        sounds.playSelect()
        prepare()
    }

    func deselect() {
        light.impactOccurred(intensity: 0.48)
        sounds.playDeselect()
        prepare()
    }

    func invalid() {
        light.impactOccurred(intensity: 0.3)
        sounds.playDeselect()
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

    init() {
        configureAudioSession()
        selectPlayer = makePlayer(resource: "pressed")
        deselectPlayer = makePlayer(resource: "click")
    }

    func playSelect() {
        play(selectPlayer)
    }

    func playDeselect() {
        play(deselectPlayer)
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
            player.prepareToPlay()
            return player
        } catch {
            Self.logger.error("Failed to load interaction sound \(resource, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func play(_ player: AVAudioPlayer?) {
        guard let player else { return }
        if player.isPlaying {
            player.currentTime = 0
        }
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
