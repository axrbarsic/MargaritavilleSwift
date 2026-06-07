import AVFoundation
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
        view.setMatteStrength(matteStrength, animated: false)
        return view
    }

    func updateUIView(_ view: VideoBackgroundPlayerView, context: Context) {
        context.coordinator.configure(url: url, in: view)
        view.setMatteStrength(matteStrength, animated: true)
    }

    final class Coordinator {
        private var currentURL: URL?
        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?

        func configure(url: URL, in view: VideoBackgroundPlayerView) {
            guard currentURL != url else {
                player?.play()
                return
            }
            currentURL = url

            let item = AVPlayerItem(url: url)
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
    }
}

final class VideoBackgroundPlayerView: UIView {
    private let matteView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
    private let tintView = UIView()
    private var currentMatteStyle: UIBlurEffect.Style = .systemMaterialDark

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

        matteView.isUserInteractionEnabled = false
        tintView.isUserInteractionEnabled = false
        tintView.backgroundColor = UIColor(red: 0.0, green: 0.18, blue: 0.08, alpha: 1)

        addSubview(matteView)
        addSubview(tintView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        matteView.frame = bounds
        tintView.frame = bounds
    }

    func setMatteStrength(_ value: Double, animated: Bool) {
        let normalized = min(max(value, 0), 1)
        let style = blurStyle(for: normalized)
        if style != currentMatteStyle {
            currentMatteStyle = style
            matteView.effect = UIBlurEffect(style: style)
        }

        let apply = {
            if normalized <= 0.01 {
                self.matteView.alpha = 0
                self.tintView.alpha = 0
            } else {
                self.matteView.alpha = CGFloat(0.34 + normalized * 0.58)
                self.tintView.alpha = CGFloat(0.08 + normalized * 0.18)
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

    private func blurStyle(for value: Double) -> UIBlurEffect.Style {
        if value >= 0.68 {
            return .systemThickMaterialDark
        }
        if value >= 0.34 {
            return .systemMaterialDark
        }
        return .systemThinMaterialDark
    }
}
