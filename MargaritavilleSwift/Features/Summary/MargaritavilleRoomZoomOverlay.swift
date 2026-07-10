import SwiftUI

struct MargaritavilleRoomZoomOverlay: View {
    let room: RoomCell
    let namespace: Namespace.ID
    let statusPaletteSaturation: Double
    let onCollapse: () -> Void

    @Environment(\.interactionFeedback) private var feedback

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                    .opacity(0.38)
                    .ignoresSafeArea()
                    .transition(.opacity)

                zoomedRoom(proxy: proxy)
                    .matchedGeometryEffect(id: room.id, in: namespace)
                    .frame(width: cardSide(proxy), height: cardSide(proxy))
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Увеличенная комната \(room.id)")
    }

    private func zoomedRoom(proxy: GeometryProxy) -> some View {
        let side = cardSide(proxy)
        return RoundedRectangle(cornerRadius: 34, style: .continuous)
            .fill(fillColor)
            .overlay {
                VStack(spacing: max(12, side * 0.06)) {
                    Text(room.id)
                        .font(.system(size: side * 0.27, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.42)

                    Text(timeLabel)
                        .font(.system(size: side * 0.085, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                }
                .foregroundStyle(OceanKeyTheme.roomForeground)
                .shadow(color: .white.opacity(0.20), radius: 0.8, x: 0, y: 0)
                .padding(side * 0.08)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .bottomTrailing) {
                RoomMediaIndicator(room: room)
                    .scaleEffect(1.35)
                    .padding(28)
                    .allowsHitTesting(false)
            }
            .shadow(color: fillColor.opacity(0.48), radius: 42, x: 0, y: 0)
            .shadow(color: .black.opacity(0.42), radius: 30, x: 0, y: 22)
            .contentShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .onLongPressGesture(
                minimumDuration: 0.36,
                maximumDistance: 24,
                perform: collapse
            )
    }

    private func cardSide(_ proxy: GeometryProxy) -> CGFloat {
        min(proxy.size.width - 24, proxy.size.height - 150)
    }

    private var fillColor: Color {
        OceanKeyTheme.fill(
            for: room.status(in: .simpleCycle),
            saturation: statusPaletteSaturation,
            usesPurpleScheduled: false
        )
    }

    private var timeLabel: String {
        let date = room.status(in: .simpleCycle) == .scheduled
            ? room.scheduledTime
            : (room.statusChangedAt ?? room.timeline.selectedAt)
        return date.map(margaritavilleZoomTimeFormatter.string(from:)) ?? "--"
    }

    private func collapse() {
        feedback.holdCommitHapticOnly()
        onCollapse()
    }
}

private let margaritavilleZoomTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "h:mm a"
    return formatter
}()
