import AVFoundation
import CoreImage
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
        view.setTuning(tuning, animated: true)
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
        private let matteFilter = VideoMatteFilter()
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
            item.videoComposition = VideoMatteCompositionFactory.makeComposition(
                asset: asset,
                matteFilter: matteFilter
            )
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
            matteFilter.setTuning(tuning)
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

    static let `default` = VideoBackgroundTuning(blur: 0.28, brightness: 0, greenTint: 0.34)
}

final class VideoBackgroundPlayerView: UIView {
    private let tintView = UIView()
    private let dimView = UIView()

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

        tintView.isUserInteractionEnabled = false
        tintView.backgroundColor = UIColor(red: 0.0, green: 0.18, blue: 0.08, alpha: 1)

        dimView.isUserInteractionEnabled = false
        dimView.backgroundColor = .black

        addSubview(tintView)
        addSubview(dimView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tintView.frame = bounds
        dimView.frame = bounds
    }

    func setTuning(_ tuning: VideoBackgroundTuning, animated: Bool) {
        let blur = min(max(tuning.blur, 0), 1)
        let green = min(max(tuning.greenTint, 0), 1)
        let brightness = min(max(tuning.brightness, -0.45), 0.45)

        let apply = {
            if green <= 0.01, blur <= 0.01 {
                self.tintView.alpha = 0
            } else {
                self.tintView.alpha = CGFloat(0.04 + blur * 0.12 + green * 0.52)
            }
            self.dimView.alpha = brightness < 0 ? CGFloat(abs(brightness) * 0.72) : 0
            self.playerLayer.opacity = Float(1 + max(0, brightness) * 0.75)
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

private final class VideoMatteFilter: @unchecked Sendable {
    private let lock = NSLock()
    private var storedTuning = VideoBackgroundTuning.default

    func setTuning(_ tuning: VideoBackgroundTuning) {
        lock.lock()
        storedTuning = VideoBackgroundTuning(
            blur: min(max(tuning.blur, 0), 1),
            brightness: min(max(tuning.brightness, -0.45), 0.45),
            greenTint: min(max(tuning.greenTint, 0), 1)
        )
        lock.unlock()
    }

    var tuning: VideoBackgroundTuning {
        lock.lock()
        let tuning = storedTuning
        lock.unlock()
        return tuning
    }
}

private enum VideoMatteCompositionFactory {
    static func makeComposition(
        asset: AVAsset,
        matteFilter: VideoMatteFilter
    ) -> AVVideoComposition {
        AVMutableVideoComposition(asset: asset) { request in
            let tuning = matteFilter.tuning
            let source = request.sourceImage
            let radius = tuning.blur > 0.01 ? 2 + tuning.blur * 34 : 0
            let blurred = radius > 0.2 ? source
                .clampedToExtent()
                .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: radius])
                .cropped(to: source.extent) : source
            let tuned = blurred.applyingFilter(
                "CIColorControls",
                parameters: [
                    kCIInputBrightnessKey: tuning.brightness,
                    kCIInputSaturationKey: 1 + tuning.greenTint * 0.22
                ]
            )
            let greened = tuned.applyingFilter(
                "CIColorMatrix",
                parameters: [
                    "inputRVector": CIVector(x: 1 - tuning.greenTint * 0.34, y: 0, z: 0, w: 0),
                    "inputGVector": CIVector(x: 0, y: 1 + tuning.greenTint * 0.38, z: 0, w: 0),
                    "inputBVector": CIVector(x: 0, y: tuning.greenTint * 0.18, z: 1 - tuning.greenTint * 0.42, w: 0),
                    "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
                ]
            )
            request.finish(with: greened, context: nil)
        }
    }
}
