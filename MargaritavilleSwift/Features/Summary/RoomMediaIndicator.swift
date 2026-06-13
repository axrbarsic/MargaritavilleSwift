import SwiftUI

struct RoomMediaIndicator: View {
    let room: RoomCell

    var body: some View {
        if let primaryIcon = room.primaryAttachmentIndicatorIcon {
            ZStack(alignment: .bottomTrailing) {
                RoomMediaCornerFlagShape()
                    .fill(.black.opacity(0.38))
                    .background {
                        RoomMediaCornerFlagShape()
                            .fill(.ultraThinMaterial.opacity(0.58))
                    }
                    .overlay {
                        RoomMediaCornerFlagShape()
                            .stroke(.white.opacity(0.30), lineWidth: 0.8)
                    }

                Image(systemName: primaryIcon)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
            }
            .frame(width: 34, height: 34)
            .overlay(alignment: .topLeading) {
                if room.attachmentIndicatorCount > 1 {
                    Text("\(room.attachmentIndicatorCount)")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .frame(height: 15)
                        .background(OceanKeyTheme.accent.opacity(0.92), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(.black.opacity(0.26), lineWidth: 0.6)
                        }
                        .offset(x: -2, y: 4)
                }
            }
        }
    }
}

private struct RoomMediaCornerFlagShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

extension RoomCell {
    var primaryAttachmentIndicatorIcon: String? {
        guard let attachments = mediaAttachments, !attachments.isEmpty else { return nil }
        if attachments.contains(where: { $0.kind == .audio }) { return "waveform" }
        if attachments.contains(where: { $0.kind == .video }) { return "video.fill" }
        if attachments.contains(where: { $0.kind == .photo }) { return "photo.fill" }
        return "paperclip"
    }

    var attachmentIndicatorCount: Int {
        mediaAttachments?.count ?? 0
    }
}
