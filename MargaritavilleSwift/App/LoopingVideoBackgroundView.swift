import AVFoundation
import OSLog
import SwiftUI
import UIKit

struct LoopingVideoBackgroundView: UIViewRepresentable {
    let url: URL
    var isActive = true
    let tuning: VideoBackgroundTuning
    @Environment(\.scenePhase) private var scenePhase

    /// Перекрытый экран ведёт себя как неактивная сцена: видео на паузе.
    private var effectivePhase: ScenePhase {
        isActive ? scenePhase : .inactive
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> VideoBackgroundPlayerView {
        let view = VideoBackgroundPlayerView()
        view.isUserInteractionEnabled = false
        context.coordinator.configure(url: url, in: view)
        context.coordinator.updateScenePhase(effectivePhase)
        context.coordinator.setTuning(tuning)
        view.setTuning(tuning, animated: false)
        return view
    }

    func updateUIView(_ view: VideoBackgroundPlayerView, context: Context) {
        context.coordinator.configure(url: url, in: view)
        context.coordinator.updateScenePhase(effectivePhase)
        context.coordinator.setTuning(tuning)
        view.setTuning(tuning, animated: false)
    }

    static func dismantleUIView(_ view: VideoBackgroundPlayerView, coordinator: Coordinator) {
        coordinator.stopPlayback()
        view.playerLayer.player = nil
    }

    @MainActor
    final class Coordinator {
        private struct SavedPlaybackState {
            let url: URL
            let position: CMTime
            let wasPlaying: Bool
        }

        private static let logger = Logger(
            subsystem: AppIdentity.loggerSubsystem,
            category: "VideoBackground"
        )

        private var currentURL: URL?
        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?
        private weak var view: VideoBackgroundPlayerView?
        private var notifications: [NSObjectProtocol] = []
        private var readyForDisplayObservation: NSKeyValueObservation?
        private var recoveryState = VideoBackgroundRecoveryState()
        private var savedPlaybackState: SavedPlaybackState?
        private var hasRenderedFrame = false
        private var playbackWasRequested = false

        @MainActor
        func configure(url: URL, in view: VideoBackgroundPlayerView) {
            self.view = view
            installReadyForDisplayObservation(in: view)
            installNotificationsIfNeeded()
            guard currentURL != url else {
                if view.playerLayer.player !== player {
                    view.playerLayer.player = player
                }
                return
            }
            currentURL = url
            savedPlaybackState = nil
            playbackWasRequested = true
            rebuildPlayer(url: url, position: nil)
        }

        @MainActor
        private func rebuildPlayer(url: URL, position: CMTime?) {
            let previousPlayer = player
            previousPlayer?.pause()
            let asset = AVURLAsset(url: url)
            let item = AVPlayerItem(asset: asset)
            let queuePlayer = AVQueuePlayer()
            queuePlayer.isMuted = true
            queuePlayer.actionAtItemEnd = .none
            queuePlayer.allowsExternalPlayback = false
            queuePlayer.preventsDisplaySleepDuringVideoPlayback = false

            let newLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)
            player = queuePlayer
            looper = newLooper
            view?.playerLayer.player = queuePlayer
            previousPlayer?.removeAllItems()

            if let position, position.isValid, position.isNumeric, position.seconds > 0 {
                queuePlayer.seek(
                    to: position,
                    toleranceBefore: CMTime(seconds: 0.08, preferredTimescale: 600),
                    toleranceAfter: CMTime(seconds: 0.08, preferredTimescale: 600)
                )
            }
            if recoveryState.canPlay, savedPlaybackState?.wasPlaying != false {
                queuePlayer.play()
            }
        }

        func setTuning(_ tuning: VideoBackgroundTuning) {
        }

        func updateScenePhase(_ phase: ScenePhase) {
            handle(phase == .active ? .sceneActive : .sceneInactive)
        }

        @MainActor
        private func handle(_ event: VideoBackgroundLifecycleEvent) {
            if event == .interruptionBegan, !recoveryState.interruptionIsActive {
                savePlaybackState()
            }
            let action = recoveryState.transition(event, health: playbackHealth)
            perform(action)
        }

        @MainActor
        private func perform(_ action: VideoBackgroundRecoveryAction) {
            switch action {
            case .none:
                return
            case .pause:
                player?.pause()
            case .resume:
                resumePlayback(rebindRenderOutput: recoveryState.pendingRecoveryGeneration != nil)
            case .rebuild(let generation):
                guard let url = savedPlaybackState?.url ?? currentURL else { return }
                Self.logger.info("video.rebuild generation=\(generation, privacy: .public)")
                rebuildPlayer(url: url, position: savedPlaybackState?.position)
            }
        }

        @MainActor
        private func resumePlayback(rebindRenderOutput: Bool) {
            guard recoveryState.canPlay, let player else { return }
            if rebindRenderOutput, let view {
                view.playerLayer.player = nil
                view.playerLayer.player = player
            }
            player.play()
        }

        @MainActor
        private func savePlaybackState() {
            guard let currentURL else { return }
            let position = player?.currentTime() ?? .zero
            savedPlaybackState = SavedPlaybackState(
                url: currentURL,
                position: position,
                wasPlaying: playbackWasRequested
            )
        }

        @MainActor
        private var playbackHealth: VideoBackgroundPlaybackHealth {
            guard let player,
                  let item = player.currentItem,
                  player.error == nil,
                  item.status != .failed,
                  let view,
                  view.playerLayer.player === player
            else {
                return .renderPipelineLost
            }
            if recoveryState.pendingRecoveryGeneration != nil,
               hasRenderedFrame,
               !view.playerLayer.isReadyForDisplay {
                return .renderPipelineLost
            }
            return .healthy
        }

        @MainActor
        private func installReadyForDisplayObservation(in view: VideoBackgroundPlayerView) {
            guard readyForDisplayObservation == nil else { return }
            readyForDisplayObservation = view.playerLayer.observe(
                \.isReadyForDisplay,
                options: [.initial, .new]
            ) { [weak self] layer, _ in
                guard layer.isReadyForDisplay else { return }
                Task { @MainActor in
                    guard let self else { return }
                    self.hasRenderedFrame = true
                    self.handle(.renderedFrame)
                }
            }
        }

        @MainActor
        private func installNotificationsIfNeeded() {
            guard notifications.isEmpty else { return }
            notifications = [
                NotificationCenter.default.addObserver(
                    forName: AVAudioSession.interruptionNotification,
                    object: AVAudioSession.sharedInstance(),
                    queue: .main
                ) { [weak self] notification in
                    guard let rawValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                          let interruptionType = AVAudioSession.InterruptionType(rawValue: rawValue)
                    else { return }
                    Task { @MainActor in
                        self?.handle(interruptionType == .began ? .interruptionBegan : .interruptionEnded)
                    }
                },
                NotificationCenter.default.addObserver(
                    forName: AVAudioSession.mediaServicesWereResetNotification,
                    object: AVAudioSession.sharedInstance(),
                    queue: .main
                ) { [weak self] _ in
                    Task { @MainActor in self?.handle(.mediaServicesWereReset) }
                },
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemPlaybackStalled,
                    object: nil,
                    queue: .main
                ) { [weak self] notification in
                    let stalledItemID = (notification.object as? AVPlayerItem).map(ObjectIdentifier.init)
                    Task { @MainActor in
                        guard let self,
                              let stalledItemID,
                              let currentItem = self.player?.currentItem,
                              stalledItemID == ObjectIdentifier(currentItem)
                        else { return }
                        self.handle(.playbackStalled)
                    }
                },
                NotificationCenter.default.addObserver(
                    forName: AudioCaptureActivityMonitor.activityDidChangeNotification,
                    object: AudioCaptureActivityMonitor.shared,
                    queue: .main
                ) { [weak self] _ in
                    Task { @MainActor in
                        self?.handle(.captureOwnershipChanged(
                            isActive: AudioCaptureActivityMonitor.shared.isCaptureActive
                        ))
                    }
                }
            ]
            handle(.captureOwnershipChanged(
                isActive: AudioCaptureActivityMonitor.shared.isCaptureActive
            ))
        }

        func stopPlayback() {
            notifications.forEach(NotificationCenter.default.removeObserver)
            notifications.removeAll()
            readyForDisplayObservation?.invalidate()
            readyForDisplayObservation = nil
            player?.pause()
            player?.removeAllItems()
            player = nil
            looper = nil
            view?.playerLayer.player = nil
            view = nil
            currentURL = nil
            savedPlaybackState = nil
            playbackWasRequested = false
        }
    }
}

struct VideoBackgroundTuning: Equatable {
    var blur: Double
    var brightness: Double
    var greenTint: Double
    var gridIntensity: Double

    static let `default` = VideoBackgroundTuning(blur: 0.28, brightness: 0.08, greenTint: 0.34, gridIntensity: 0)
}

final class VideoBackgroundPlayerView: UIView {
    private let blurView = VariableBlurEffectView()
    private let tintView = UIView()
    private let dimView = UIView()
    private let gridView = VideoGridOverlayView()

    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.masksToBounds = true
        playerLayer.backgroundColor = UIColor.black.cgColor
        playerLayer.needsDisplayOnBoundsChange = true

        blurView.isUserInteractionEnabled = false
        blurView.backgroundColor = .clear
        tintView.isUserInteractionEnabled = false
        tintView.backgroundColor = UIColor(red: 0.0, green: 0.18, blue: 0.08, alpha: 1)

        dimView.isUserInteractionEnabled = false
        dimView.backgroundColor = .black

        addSubview(blurView)
        addSubview(tintView)
        addSubview(gridView)
        addSubview(dimView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        blurView.frame = bounds
        tintView.frame = bounds
        gridView.frame = bounds
        dimView.frame = bounds
    }

    func setTuning(_ tuning: VideoBackgroundTuning, animated: Bool) {
        let blur = min(max(tuning.blur, 0), 1)
        let green = min(max(tuning.greenTint, 0), 1)
        let brightness = min(max(tuning.brightness, -0.85), 0.85)
        let grid = min(max(tuning.gridIntensity, 0), 1)

        let apply = {
            self.blurView.blurIntensity = blur
            self.tintView.alpha = green <= 0.01 ? 0 : CGFloat(0.04 + green * 0.76)
            self.gridView.intensity = grid
            self.dimView.alpha = brightness < 0 ? CGFloat(abs(brightness) * 0.82) : 0
            self.playerLayer.opacity = Float(1 + max(0, brightness) * 0.35)
        }

        guard animated else {
            apply()
            return
        }

        UIView.animate(
            withDuration: 0.16,
            delay: 0,
            options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseOut],
            animations: apply
        )
    }
}

private final class VariableBlurEffectView: UIVisualEffectView {
    private var animator: UIViewPropertyAnimator?
    private var currentIntensity: Double = -1

    var blurIntensity: Double {
        get { currentIntensity }
        set {
            let normalized = min(max(newValue, 0), 1)
            guard abs(normalized - currentIntensity) > 0.005 else { return }
            currentIntensity = normalized
            isHidden = normalized <= 0.001
            alpha = normalized <= 0.001 ? 0 : 1
            applyBlur(intensity: normalized)
        }
    }

    override init(effect: UIVisualEffect?) {
        super.init(effect: effect)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func applyBlur(intensity: Double) {
        animator?.stopAnimation(true)
        effect = nil

        guard intensity > 0.001 else { return }

        let animator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
            self.effect = UIBlurEffect(style: .regular)
        }
        animator.pausesOnCompletion = true
        animator.fractionComplete = CGFloat(intensity)
        self.animator = animator
    }
}

private final class VideoGridOverlayView: UIView {
    private var cachedIntensityStep = -1

    var intensity: Double = 0 {
        didSet {
            let normalized = min(max(intensity, 0), 1)
            let step = Int((normalized * 12).rounded())
            alpha = CGFloat(normalized)
            isHidden = step == 0
            guard step != cachedIntensityStep else { return }
            cachedIntensityStep = step
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        isUserInteractionEnabled = false
        contentMode = .redraw
        alpha = 0
        isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard cachedIntensityStep > 0, let context = UIGraphicsGetCurrentContext() else { return }
        context.clear(rect)

        let normalized = Double(cachedIntensityStep) / 12.0
        let scale = window?.screen.scale ?? UIScreen.main.scale
        let spacing = max(2.0, 3.0 * scale)
        let majorSpacing = spacing * 4
        let minorAlpha = CGFloat(0.10 + normalized * 0.24)
        let majorAlpha = CGFloat(0.05 + normalized * 0.13)
        let lineWidth = 1.0 / scale

        context.setLineWidth(lineWidth)
        context.setShouldAntialias(false)

        context.setStrokeColor(UIColor.white.withAlphaComponent(minorAlpha).cgColor)
        stride(from: CGFloat(0), through: rect.maxY, by: spacing).forEach { y in
            context.move(to: CGPoint(x: rect.minX, y: y.rounded(.down)))
            context.addLine(to: CGPoint(x: rect.maxX, y: y.rounded(.down)))
        }
        context.strokePath()

        context.setStrokeColor(UIColor.black.withAlphaComponent(majorAlpha).cgColor)
        stride(from: CGFloat(0), through: rect.maxX, by: majorSpacing).forEach { x in
            context.move(to: CGPoint(x: x.rounded(.down), y: rect.minY))
            context.addLine(to: CGPoint(x: x.rounded(.down), y: rect.maxY))
        }
        context.strokePath()
    }
}
