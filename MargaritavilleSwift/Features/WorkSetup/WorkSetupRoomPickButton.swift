import SwiftUI

struct RoomPickButton: View {
    let room: RoomID
    let selected: Bool
    let reservation: WorkSetupRoomReservation?
    let layout: HotelSummaryLayout
    let dayCategory: RoomDayCategory?
    let dayCategoryTime: Date?
    let showsDayCategory: Bool
    let selectionColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                roomNumber
                if let reservation {
                    VStack(spacing: 3) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .black))
                        Text(reservation.displayName)
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                    }
                    .foregroundStyle(.white.opacity(0.74))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
                if showsDayCategory, selected, let dayCategory {
                    categoryBadge(dayCategory)
                        .padding(.horizontal, 5)
                        .padding(.bottom, 5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: fixedHeight)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(stroke, lineWidth: selected ? 1.4 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(reservation != nil)
        .accessibilityHint(reservation == nil ? "" : "Комната уже закреплена за \(reservation?.displayName ?? "другой уборщицей").")
    }

    private var roomNumber: some View {
        Text(RoomCatalog.displayRoomID(room, compactLetteredLabels: true))
            .font(.system(size: layout == .squareGrid4 ? 32 : 20, weight: .black, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .padding(.horizontal, 5)
    }

    private var fixedHeight: CGFloat? {
        layout == .squareGrid4 ? 64 : 48
    }

    private func categoryBadge(_ dayCategory: RoomDayCategory) -> some View {
        HStack(spacing: 3) {
            Text(dayCategory.shortTitle)
            if let dayCategoryTime {
                Text(Self.timeFormatter.string(from: dayCategoryTime))
                    .monospacedDigit()
            }
        }
        .font(.system(size: 10, weight: .black, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.70)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(Color.black.opacity(0.22))
        .clipShape(Capsule())
    }

    private var foreground: Color {
        reservation == nil ? (selected ? OceanKeyTheme.roomForeground : .white) : .white.opacity(0.38)
    }

    private var background: Color {
        if reservation != nil { return Color.gray.opacity(0.22) }
        if selected, let dayCategory {
            return OceanKeyTheme.fill(for: dayCategory)
        }
        return selected ? selectionColor : OceanKeyTheme.surface.opacity(0.72)
    }

    private var stroke: Color {
        if let reservation { return reservation.paletteColor.opacity(0.45) }
        return selected ? .white.opacity(0.55) : OceanKeyTheme.accent.opacity(0.16)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}
