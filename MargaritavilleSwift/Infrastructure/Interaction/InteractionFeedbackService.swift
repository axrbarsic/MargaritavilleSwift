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
            tap: deferred { service.tap(soundPackV2: soundPackV2, hapticsV2: hapticsV2) },
            confirm: deferred { service.confirm(soundPackV2: soundPackV2, hapticsV2: hapticsV2) },
            longPress: deferred { service.longPress(soundPackV2: soundPackV2, hapticsV2: hapticsV2) },
            holdStart: deferred { service.holdStart(hapticsV2: hapticsV2) },
            holdWarning: deferred { service.holdWarning(hapticsV2: hapticsV2) },
            holdCommit: deferred { service.holdCommit(soundPackV2: soundPackV2, hapticsV2: hapticsV2) },
            select: deferred { service.select(soundPackV2: soundPackV2, hapticsV2: hapticsV2) },
            deselect: deferred { service.deselect(soundPackV2: soundPackV2, hapticsV2: hapticsV2) },
            invalid: deferred { service.invalid(soundPackV2: soundPackV2, hapticsV2: hapticsV2) }
        )
    }

    private static func deferred(
        _ action: @escaping @MainActor @Sendable () -> Void
    ) -> @MainActor @Sendable () -> Void {
        {
            Task { @MainActor in
                await Task.yield()
                action()
            }
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

    init() {
        prepare()
    }

    func tap(soundPackV2: Bool = false, hapticsV2: Bool = false) {
        light.impactOccurred(intensity: hapticsV2 ? 0.42 : 0.55)
        if soundPackV2 {
            sounds.playTapAccent()
        }
        schedulePrepare()
    }

    func confirm(soundPackV2: Bool = false, hapticsV2: Bool = false) {
        medium.impactOccurred(intensity: hapticsV2 ? 0.96 : 0.82)
        if hapticsV2 {
            notification.notificationOccurred(.success)
        }
        sounds.playSelect(variant: soundPackV2 ? .confirm : .plain)
        schedulePrepare()
    }

    func longPress(soundPackV2: Bool = false, hapticsV2: Bool = false) {
        heavy.impactOccurred(intensity: hapticsV2 ? 1.0 : 0.9)
        if hapticsV2 {
            medium.impactOccurred(intensity: 0.45)
        }
        sounds.playSelect(variant: soundPackV2 ? .deep : .plain)
        schedulePrepare()
    }

    func holdStart(hapticsV2: Bool = false) {
        selection.selectionChanged()
        if hapticsV2 {
            light.impactOccurred(intensity: 0.25)
        }
        schedulePrepare()
    }

    func holdWarning(hapticsV2: Bool = false) {
        light.impactOccurred(intensity: hapticsV2 ? 0.95 : 0.7)
        if hapticsV2 {
            notification.notificationOccurred(.warning)
        }
        schedulePrepare()
    }

    func holdCommit(soundPackV2: Bool = false, hapticsV2: Bool = false) {
        heavy.impactOccurred(intensity: hapticsV2 ? 1.0 : 0.92)
        if hapticsV2 {
            notification.notificationOccurred(.success)
        }
        sounds.playSelect(variant: soundPackV2 ? .commit : .plain)
        schedulePrepare()
    }

    func select(soundPackV2: Bool = false, hapticsV2: Bool = false) {
        medium.impactOccurred(intensity: hapticsV2 ? 0.86 : 0.72)
        sounds.playSelect(variant: soundPackV2 ? .select : .plain)
        schedulePrepare()
    }

    func deselect(soundPackV2: Bool = false, hapticsV2: Bool = false) {
        light.impactOccurred(intensity: hapticsV2 ? 0.36 : 0.48)
        sounds.playDeselect(variant: soundPackV2 ? .soft : .plain)
        schedulePrepare()
    }

    func invalid(soundPackV2: Bool = false, hapticsV2: Bool = false) {
        light.impactOccurred(intensity: hapticsV2 ? 0.18 : 0.3)
        if hapticsV2 {
            notification.notificationOccurred(.error)
        }
        sounds.playDeselect(variant: soundPackV2 ? .invalid : .plain)
        schedulePrepare()
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
}

private final class InteractionSoundPlayer: @unchecked Sendable {
    private static let logger = Logger(subsystem: AppIdentity.loggerSubsystem, category: "InteractionSound")

    private let queue = DispatchQueue(
        label: "\(AppIdentity.loggerSubsystem).interaction-sound",
        qos: .userInteractive
    )
    private var selectPlayers: [AVAudioPlayer] = []
    private var deselectPlayers: [AVAudioPlayer] = []
    private var selectCursor = 0
    private var deselectCursor = 0
    private var audioSessionNeedsRefresh = false
    private var audioSessionObservers: [NSObjectProtocol] = []

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
        queue.sync {
            configureAudioSession()
            selectPlayers = makePlayers(resource: "pressed")
            deselectPlayers = makePlayers(resource: "click")
        }
        observeAudioSessionChanges()
    }

    deinit {
        for observer in audioSessionObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func playSelect(variant: SelectVariant = .plain) {
        switch variant {
        case .plain:
            enqueueSelect(volume: 0.20, rate: 1.0, pan: 0)
        case .confirm:
            enqueueSelect(volume: 0.24, rate: 1.12, pan: 0.05)
        case .deep:
            enqueueSelect(volume: 0.23, rate: 0.82, pan: -0.08)
        case .commit:
            enqueueSelect(volume: 0.28, rate: 1.24, pan: 0.10)
        case .select:
            enqueueSelect(volume: 0.22, rate: 1.06, pan: -0.04)
        }
    }

    func playDeselect(variant: DeselectVariant = .plain) {
        switch variant {
        case .plain:
            enqueueDeselect(volume: 0.20, rate: 1.0, pan: 0)
        case .soft:
            enqueueDeselect(volume: 0.15, rate: 0.92, pan: -0.05)
        case .invalid:
            enqueueDeselect(volume: 0.23, rate: 0.72, pan: 0.08)
        }
    }

    func playTapAccent() {
        enqueueDeselect(volume: 0.11, rate: 1.36, pan: 0.03)
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            audioSessionNeedsRefresh = false
        } catch {
            Self.logger.error("Failed to configure interaction audio: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func observeAudioSessionChanges() {
        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            AVAudioSession.interruptionNotification,
            AVAudioSession.routeChangeNotification,
            AVAudioSession.mediaServicesWereResetNotification
        ]
        audioSessionObservers = names.map { name in
            center.addObserver(
                forName: name,
                object: AVAudioSession.sharedInstance(),
                queue: nil
            ) { [weak self] _ in
                guard let soundPlayer = self else { return }
                soundPlayer.queue.async { [weak soundPlayer] in
                    soundPlayer?.audioSessionNeedsRefresh = true
                }
            }
        }
    }

    private func makePlayers(resource: String) -> [AVAudioPlayer] {
        (0..<4).compactMap { _ in makePlayer(resource: resource) }
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

    private func playSelect(volume: Float, rate: Float, pan: Float) {
        guard !selectPlayers.isEmpty else { return }
        let player = nextPlayer(players: selectPlayers, cursor: &selectCursor)
        play(player, volume: volume, rate: rate, pan: pan)
    }

    private func playDeselect(volume: Float, rate: Float, pan: Float) {
        guard !deselectPlayers.isEmpty else { return }
        let player = nextPlayer(players: deselectPlayers, cursor: &deselectCursor)
        play(player, volume: volume, rate: rate, pan: pan)
    }

    private func enqueueSelect(volume: Float, rate: Float, pan: Float) {
        queue.async { [weak self] in
            self?.playSelect(volume: volume, rate: rate, pan: pan)
        }
    }

    private func enqueueDeselect(volume: Float, rate: Float, pan: Float) {
        queue.async { [weak self] in
            self?.playDeselect(volume: volume, rate: rate, pan: pan)
        }
    }

    private func nextPlayer(players: [AVAudioPlayer], cursor: inout Int) -> AVAudioPlayer {
        if let available = players.first(where: { !$0.isPlaying }) {
            return available
        }
        let player = players[cursor % players.count]
        cursor = (cursor + 1) % players.count
        return player
    }

    private func play(_ player: AVAudioPlayer, volume: Float, rate: Float, pan: Float) {
        if audioSessionNeedsRefresh {
            configureAudioSession()
        }
        if player.isPlaying {
            player.stop()
        }
        player.currentTime = 0
        player.volume = volume
        player.rate = rate
        player.pan = pan
        if !player.play() {
            configureAudioSession()
            player.prepareToPlay()
            player.currentTime = 0
            _ = player.play()
        }
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
