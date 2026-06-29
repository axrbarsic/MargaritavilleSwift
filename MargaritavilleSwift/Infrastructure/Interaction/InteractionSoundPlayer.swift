import AVFoundation
import OSLog

final class InteractionSoundPlayer: @unchecked Sendable {
    private static let logger = Logger(subsystem: AppIdentity.loggerSubsystem, category: "InteractionSound")

    private let queue = DispatchQueue(
        label: "\(AppIdentity.loggerSubsystem).interaction-sound",
        qos: .userInteractive
    )
    private var selectPlayers: [AVAudioPlayer] = []
    private var deselectPlayers: [AVAudioPlayer] = []
    private var customPlayers: [String: [AVAudioPlayer]] = [:]
    private var selectCursor = 0
    private var deselectCursor = 0
    private var customCursors: [String: Int] = [:]
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
        case .plain: enqueueSelect(volume: 0.20, rate: 1.0, pan: 0)
        case .confirm: enqueueSelect(volume: 0.24, rate: 1.12, pan: 0.05)
        case .deep: enqueueSelect(volume: 0.23, rate: 0.82, pan: -0.08)
        case .commit: enqueueSelect(volume: 0.28, rate: 1.24, pan: 0.10)
        case .select: enqueueSelect(volume: 0.22, rate: 1.06, pan: -0.04)
        }
    }

    func playDeselect(variant: DeselectVariant = .plain) {
        switch variant {
        case .plain: enqueueDeselect(volume: 0.20, rate: 1.0, pan: 0)
        case .soft: enqueueDeselect(volume: 0.15, rate: 0.92, pan: -0.05)
        case .invalid: enqueueDeselect(volume: 0.23, rate: 0.72, pan: 0.08)
        }
    }

    func playTapAccent() {
        enqueueDeselect(volume: 0.11, rate: 1.36, pan: 0.03)
    }

    func playEffect(_ sound: InteractionSoundAsset) {
        switch sound {
        case .none:
            return
        case .legacyClick:
            playDeselect(variant: .plain)
            return
        case .legacyPressed:
            playSelect(variant: .confirm)
            return
        default:
            break
        }
        guard let resource = sound.resourceName else { return }
        enqueueCustom(resource: resource, volume: 0.30, rate: 1.0, pan: 0)
    }

    func restoreAudioSession() {
        queue.async { [weak self] in
            guard let self else { return }
            configureAudioSession()
            selectPlayers.forEach { $0.prepareToPlay() }
            deselectPlayers.forEach { $0.prepareToPlay() }
            customPlayers.values.flatMap { $0 }.forEach { $0.prepareToPlay() }
        }
    }

    private func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            audioSessionNeedsRefresh = false
        } catch {
            Self.logger.error("Failed to activate interaction audio: \(error.localizedDescription, privacy: .public)")
            audioSessionNeedsRefresh = true
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            activateAudioSession()
        } catch {
            Self.logger.error("Failed to configure interaction audio: \(error.localizedDescription, privacy: .public)")
            audioSessionNeedsRefresh = true
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
            center.addObserver(forName: name, object: AVAudioSession.sharedInstance(), queue: nil) { [weak self] _ in
                self?.queue.async { [weak self] in
                    self?.audioSessionNeedsRefresh = true
                }
            }
        }
    }

    private func makePlayers(resource: String) -> [AVAudioPlayer] {
        (0..<4).compactMap { _ in makePlayer(resource: resource) }
    }

    private func makePlayer(resource: String) -> AVAudioPlayer? {
        guard let url = Self.resourceURL(resource: resource) else { return nil }
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

    private static func resourceURL(resource: String) -> URL? {
        let bundles = [Bundle(for: InteractionSoundPlayer.self), Bundle.main]
        for bundle in bundles {
            if let url = bundle.url(forResource: resource, withExtension: "wav") {
                return url
            }
            if let url = bundle.url(forResource: resource, withExtension: "wav", subdirectory: "Sounds/SharedShortSFX") {
                return url
            }
        }
        return nil
    }

    private func playSelect(volume: Float, rate: Float, pan: Float) {
        guard !selectPlayers.isEmpty else { return }
        play(nextPlayer(players: selectPlayers, cursor: &selectCursor), volume: volume, rate: rate, pan: pan)
    }

    private func playDeselect(volume: Float, rate: Float, pan: Float) {
        guard !deselectPlayers.isEmpty else { return }
        play(nextPlayer(players: deselectPlayers, cursor: &deselectCursor), volume: volume, rate: rate, pan: pan)
    }

    private func playCustom(resource: String, volume: Float, rate: Float, pan: Float) {
        if customPlayers[resource] == nil {
            customPlayers[resource] = makePlayers(resource: resource)
        }
        guard let players = customPlayers[resource], !players.isEmpty else { return }
        var cursor = customCursors[resource] ?? 0
        let player = nextPlayer(players: players, cursor: &cursor)
        customCursors[resource] = cursor
        play(player, volume: volume, rate: rate, pan: pan)
    }

    private func enqueueSelect(volume: Float, rate: Float, pan: Float) {
        queue.async { [weak self] in self?.playSelect(volume: volume, rate: rate, pan: pan) }
    }

    private func enqueueDeselect(volume: Float, rate: Float, pan: Float) {
        queue.async { [weak self] in self?.playDeselect(volume: volume, rate: rate, pan: pan) }
    }

    private func enqueueCustom(resource: String, volume: Float, rate: Float, pan: Float) {
        queue.async { [weak self] in self?.playCustom(resource: resource, volume: volume, rate: rate, pan: pan) }
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
        } else {
            activateAudioSession()
        }
        stopAllPlayers()
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

    private func stopAllPlayers() {
        selectPlayers.forEach(stop)
        deselectPlayers.forEach(stop)
        customPlayers.values.flatMap { $0 }.forEach(stop)
    }

    private func stop(_ player: AVAudioPlayer) {
        if player.isPlaying {
            player.stop()
        }
        player.currentTime = 0
    }
}
