import AVFoundation
import SwiftUI
import UIKit

struct LoopingVideoBackgroundView: UIViewRepresentable {
    let url: URL
    let tuning: VideoBackgroundTuning

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> VideoBackgroundPlayerView {
        let view = VideoBackgroundPlayerView()
        view.isUserInteractionEnabled = false
        context.coordinator.configure(url: url, in: view)
        context.coordinator.setTuning(tuning)
        view.setTuning(tuning, animated: false)
        return view
    }

    func updateUIView(_ view: VideoBackgroundPlayerView, context: Context) {
        context.coordinator.configure(url: url, in: view)
        context.coordinator.setTuning(tuning)
        view.setTuning(tuning, animated: false)
    }

    static func dismantleUIView(_ view: VideoBackgroundPlayerView, coordinator: Coordinator) {
        coordinator.stopPlayback()
        view.playerLayer.player = nil
    }

    @MainActor
    final class Coordinator {
        private var currentURL: URL?
        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?
        private weak var view: VideoBackgroundPlayerView?
        private var watchdog: Timer?
        private var notifications: [NSObjectProtocol] = []

        @MainActor
        func configure(url: URL, in view: VideoBackgroundPlayerView) {
            self.view = view
            guard currentURL != url else {
                ensurePlayback()
                return
            }
            currentURL = url
            rebuildPlayer(url: url, in: view)
        }

        @MainActor
        private func rebuildPlayer(url: URL, in view: VideoBackgroundPlayerView) {
            stopPlayback()

            let asset = AVURLAsset(url: url)
            let item = AVPlayerItem(asset: asset)
            let queuePlayer = AVQueuePlayer()
            queuePlayer.isMuted = true
            queuePlayer.actionAtItemEnd = .none
            queuePlayer.allowsExternalPlayback = false
            queuePlayer.preventsDisplaySleepDuringVideoPlayback = false

            player = queuePlayer
            looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
            view.playerLayer.player = queuePlayer
            queuePlayer.play()
            startWatchdog()
            installNotifications()
        }

        func setTuning(_ tuning: VideoBackgroundTuning) {
        }

        @MainActor
        private func ensurePlayback() {
            guard let player else { return }
            if player.rate == 0 {
                player.play()
            }
            if player.currentItem == nil, let currentURL, let view {
                rebuildPlayer(url: currentURL, in: view)
            }
        }

        @MainActor
        private func startWatchdog() {
            watchdog?.invalidate()
            watchdog = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.ensurePlayback()
                }
            }
            watchdog?.tolerance = 0.45
        }

        @MainActor
        private func installNotifications() {
            notifications.forEach(NotificationCenter.default.removeObserver)
            notifications = [
                NotificationCenter.default.addObserver(
                    forName: UIApplication.willEnterForegroundNotification,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    Task { @MainActor in self?.ensurePlayback() }
                },
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemPlaybackStalled,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    Task { @MainActor in self?.ensurePlayback() }
                }
            ]
        }

        func stopPlayback() {
            watchdog?.invalidate()
            watchdog = nil
            notifications.forEach(NotificationCenter.default.removeObserver)
            notifications.removeAll()
            player?.pause()
            player?.removeAllItems()
            player = nil
            looper = nil
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
    private let blurView = UIVisualEffectView(effect: nil)
    private let tintView = UIView()
    private let dimView = UIView()
    private let gridView = VideoGridOverlayView()
    private var currentBlurStep = -1

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
            let blurStep = Int((blur * 5).rounded())
            if blurStep != self.currentBlurStep {
                self.currentBlurStep = blurStep
                self.blurView.effect = Self.blurEffect(for: blurStep)
            }
            self.blurView.alpha = blurStep == 0 ? 0 : CGFloat(0.18 + blur * 0.70)
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

    private static func blurEffect(for step: Int) -> UIBlurEffect? {
        switch step {
        case 0:
            nil
        case 1:
            UIBlurEffect(style: .systemUltraThinMaterialDark)
        case 2:
            UIBlurEffect(style: .systemThinMaterialDark)
        case 3:
            UIBlurEffect(style: .systemMaterialDark)
        case 4:
            UIBlurEffect(style: .systemThickMaterialDark)
        default:
            UIBlurEffect(style: .systemChromeMaterialDark)
        }
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
