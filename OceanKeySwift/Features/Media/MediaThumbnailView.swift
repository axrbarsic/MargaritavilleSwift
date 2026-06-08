import AVFoundation
import SwiftUI
import UIKit

struct MediaThumbnailView: View {
    let attachment: MediaAttachment
    let fileStore = LocalMediaFileStore()

    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(.black.opacity(0.32))
                        .overlay {
                            ProgressView()
                                .tint(OceanKeyTheme.accent)
                        }
                }
            }
            .frame(width: 96, height: 132)
            .clipped()

            HStack(spacing: 4) {
                Image(systemName: iconName)
                Text(timeLabel)
            }
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(.black.opacity(0.66))
            .clipShape(Capsule())
            .padding(6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(OceanKeyTheme.accent.opacity(0.18), lineWidth: 1)
        }
        .task(id: attachment.id) {
            image = await loadThumbnail()
        }
    }

    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: attachment.createdAt)
    }

    private func loadThumbnail() async -> UIImage? {
        let url = fileStore.url(for: attachment)
        switch attachment.kind {
        case .photo:
            return await Task.detached {
                UIImage(contentsOfFile: url.path)
            }.value
        case .video:
            return await Task.detached {
                let asset = AVAsset(url: url)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                let time = CMTime(seconds: 0.2, preferredTimescale: 600)
                guard let image = try? generator.copyCGImage(at: time, actualTime: nil) else {
                    return nil
                }
                return UIImage(cgImage: image)
            }.value
        case .audio:
            return nil
        }
    }

    private var iconName: String {
        switch attachment.kind {
        case .photo:
            "camera.fill"
        case .video:
            "play.fill"
        case .audio:
            "waveform"
        }
    }
}
