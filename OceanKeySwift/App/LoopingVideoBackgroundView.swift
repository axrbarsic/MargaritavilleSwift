import AVFoundation
import SwiftUI
import UIKit

struct LoopingVideoBackgroundView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PlayerLayerView {
        let view = PlayerLayerView()
        view.backgroundColor = .black
        view.playerLayer.videoGravity = .resizeAspectFill
        view.isUserInteractionEnabled = false
        context.coordinator.configure(url: url, in: view)
        return view
    }

    func updateUIView(_ view: PlayerLayerView, context: Context) {
        context.coordinator.configure(url: url, in: view)
    }

    final class Coordinator {
        private var currentURL: URL?
        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?

        func configure(url: URL, in view: PlayerLayerView) {
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

final class PlayerLayerView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}

struct BackgroundMaterialView: UIViewRepresentable {
    let alpha: CGFloat

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        view.isUserInteractionEnabled = false
        view.alpha = alpha
        return view
    }

    func updateUIView(_ view: UIVisualEffectView, context: Context) {
        view.alpha = alpha
    }
}
