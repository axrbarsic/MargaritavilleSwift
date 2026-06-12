import SwiftUI

struct MediaAttachmentGrid: View {
    let attachments: [MediaAttachment]
    let previewsEnabled: Bool
    let onOpen: (MediaAttachment) -> Void
    let onDelete: (MediaAttachment) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(attachments) { attachment in
                MediaAttachmentGridCard(
                    attachment: attachment,
                    previewsEnabled: previewsEnabled,
                    onOpen: { onOpen(attachment) },
                    onDelete: { onDelete(attachment) }
                )
            }
        }
    }
}

private struct MediaAttachmentGridCard: View {
    let attachment: MediaAttachment
    let previewsEnabled: Bool
    let onOpen: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onOpen) {
                MediaThumbnailView(
                    attachment: attachment,
                    isPreviewActive: previewsEnabled
                )
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(OceanKeyTheme.pending.opacity(0.94), in: Circle())
                    .shadow(color: .black.opacity(0.34), radius: 3, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            .padding(7)
            .accessibilityLabel("Удалить медиа")
        }
        .frame(maxWidth: .infinity)
    }
}
