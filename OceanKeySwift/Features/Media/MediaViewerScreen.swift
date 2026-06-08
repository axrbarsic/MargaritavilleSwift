import AVKit
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
                    MediaViewerPage(attachment: attachment)
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
    private let fileStore = LocalMediaFileStore()

    var body: some View {
        switch attachment.kind {
        case .photo:
            ZoomablePhotoView(url: fileStore.url(for: attachment))
        case .video:
            FullScreenVideoPlayer(url: fileStore.url(for: attachment))
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
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Color.black

            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { notification in
                        guard notification.object as? AVPlayerItem == player.currentItem else { return }
                        player.seek(to: .zero)
                        player.play()
                    }
            } else {
                ProgressView()
                    .tint(OceanKeyTheme.accent)
            }
        }
        .onAppear {
            let nextPlayer = AVPlayer(url: url)
            player = nextPlayer
            nextPlayer.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
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
