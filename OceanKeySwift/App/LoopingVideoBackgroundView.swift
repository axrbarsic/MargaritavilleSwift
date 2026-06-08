import AVFoundation
import CoreImage
import SwiftUI
import UIKit

struct LoopingVideoBackgroundView: UIViewRepresentable {
    let url: URL
    let matteStrength: Double

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> VideoBackgroundPlayerView {
        let view = VideoBackgroundPlayerView()
        view.isUserInteractionEnabled = false
        context.coordinator.configure(url: url, in: view)
        context.coordinator.setMatteStrength(matteStrength)
        view.setMatteStrength(matteStrength, animated: false)
        return view
    }

    func updateUIView(_ view: VideoBackgroundPlayerView, context: Context) {
        context.coordinator.configure(url: url, in: view)
        context.coordinator.setMatteStrength(matteStrength)
        view.setMatteStrength(matteStrength, animated: true)
    }

    final class Coordinator {
        private var currentURL: URL?
        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?
        private let matteFilter = VideoMatteFilter()

        @MainActor
        func configure(url: URL, in view: VideoBackgroundPlayerView) {
            guard currentURL != url else {
                player?.play()
                return
            }
            currentURL = url

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
        }

        func setMatteStrength(_ value: Double) {
            matteFilter.setStrength(value)
        }
    }
}

final class VideoBackgroundPlayerView: UIView {
    private let tintView = UIView()

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

        addSubview(tintView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tintView.frame = bounds
    }

    func setMatteStrength(_ value: Double, animated: Bool) {
        let normalized = min(max(value, 0), 1)

        let apply = {
            if normalized <= 0.01 {
                self.tintView.alpha = 0
            } else {
                self.tintView.alpha = CGFloat(0.12 + normalized * 0.26)
            }
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
    private var storedStrength: Double = 0.28

    func setStrength(_ value: Double) {
        lock.lock()
        storedStrength = min(max(value, 0), 1)
        lock.unlock()
    }

    var radius: Double {
        lock.lock()
        let strength = storedStrength
        lock.unlock()
        guard strength > 0.01 else { return 0 }
        return 2 + strength * 34
    }
}

private enum VideoMatteCompositionFactory {
    static func makeComposition(
        asset: AVAsset,
        matteFilter: VideoMatteFilter
    ) -> AVVideoComposition {
        AVMutableVideoComposition(asset: asset) { request in
            let radius = matteFilter.radius
            guard radius > 0.2 else {
                request.finish(with: request.sourceImage, context: nil)
                return
            }

            let source = request.sourceImage
            let blurred = source
                .clampedToExtent()
                .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: radius])
                .cropped(to: source.extent)
            request.finish(with: blurred, context: nil)
        }
    }
}
