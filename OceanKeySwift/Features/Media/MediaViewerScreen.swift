import AVFoundation
import SwiftUI
import UIKit

struct MediaViewerScreen: View {
    let attachments: [MediaAttachment]
    let initialAttachment: MediaAttachment

    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: MediaAttachment.ID

    init(attachments: [MediaAttachment], initialAttachment: MediaAttachment) {
        self.attachments = attachments
        self.initialAttachment = initialAttachment
        _selectedID = State(initialValue: initialAttachment.id)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            TabView(selection: $selectedID) {
                ForEach(attachments) { attachment in
                    MediaViewerPage(
                        attachment: attachment,
                        isActive: attachment.id == selectedID
                    )
                        .tag(attachment.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            topBar
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .black))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(.white)
                    .background(.black.opacity(0.62))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(counterLabel)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                if let selectedAttachment {
                    Text(timeLabel(selectedAttachment.createdAt))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }

    private var selectedAttachment: MediaAttachment? {
        attachments.first { $0.id == selectedID }
    }

    private var counterLabel: String {
        guard let index = attachments.firstIndex(where: { $0.id == selectedID }) else {
            return "1 / \(max(attachments.count, 1))"
        }
        return "\(index + 1) / \(attachments.count)"
    }

    private func timeLabel(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .month(.abbreviated)
                .day()
                .hour(.defaultDigits(amPM: .abbreviated))
                .minute(.twoDigits)
                .locale(Locale(identifier: "en_US_POSIX"))
        )
    }
}

private struct MediaViewerPage: View {
    let attachment: MediaAttachment
    let isActive: Bool
    private let fileStore = LocalMediaFileStore()

    var body: some View {
        switch attachment.kind {
        case .photo:
            ZoomablePhotoView(url: fileStore.url(for: attachment))
        case .video:
            FullScreenVideoPlayer(
                url: fileStore.url(for: attachment),
                isActive: isActive
            )
        case .audio:
            Color.black
        }
    }
}

private struct ZoomablePhotoView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 5
        scrollView.backgroundColor = .black
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard context.coordinator.loadedURL != url else { return }
        context.coordinator.loadedURL = url
        scrollView.setZoomScale(1, animated: false)
        context.coordinator.imageView?.image = UIImage(contentsOfFile: url.path)
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?
        var loadedURL: URL?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }
    }
}

private struct FullScreenVideoPlayer: View {
    let url: URL
    let isActive: Bool

    var body: some View {
        FullScreenVideoPlayerView(url: url, isActive: isActive)
            .ignoresSafeArea()
    }
}

private struct FullScreenVideoPlayerView: UIViewRepresentable {
    let url: URL
    let isActive: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> FullScreenPlayerView {
        let view = FullScreenPlayerView()
        context.coordinator.configure(url: url, isActive: isActive, in: view)
        return view
    }

    func updateUIView(_ view: FullScreenPlayerView, context: Context) {
        context.coordinator.configure(url: url, isActive: isActive, in: view)
    }

    static func dismantleUIView(_ view: FullScreenPlayerView, coordinator: Coordinator) {
        coordinator.stop()
        view.playerLayer.player = nil
    }

    final class Coordinator {
        private var currentURL: URL?
        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?

        @MainActor
        func configure(url: URL, isActive: Bool, in view: FullScreenPlayerView) {
            guard currentURL != url else {
                if isActive {
                    player?.play()
                } else {
                    player?.pause()
                }
                return
            }
            currentURL = url
            let item = AVPlayerItem(url: url)
            let queuePlayer = AVQueuePlayer()
            queuePlayer.actionAtItemEnd = .none
            queuePlayer.allowsExternalPlayback = false
            queuePlayer.preventsDisplaySleepDuringVideoPlayback = false
            player = queuePlayer
            looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
            view.playerLayer.player = queuePlayer
            if isActive {
                queuePlayer.play()
            }
        }

        func stop() {
            player?.pause()
            player?.removeAllItems()
            player = nil
            looper = nil
            currentURL = nil
        }
    }
}

private final class FullScreenPlayerView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        playerLayer.videoGravity = .resizeAspect
        playerLayer.masksToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#Preview {
    let attachment = MediaAttachment(
        id: UUID(),
        kind: .photo,
        relativePath: "Media/example.jpg",
        createdAt: Date()
    )
    MediaViewerScreen(
        attachments: [attachment],
        initialAttachment: attachment
    )
}
