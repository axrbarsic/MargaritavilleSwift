import SwiftUI

struct RoomPickButton: View {
    let room: RoomID
    let selected: Bool
    let blockedByCart: Int?
    let layout: HotelSummaryLayout
    let dayCategory: RoomDayCategory?
    let dayCategoryTime: Date?
    let showsDayCategory: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                Text(RoomCatalog.displayRoomID(room, compactLetteredLabels: true))
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .monospacedDigit()
                if let blockedByCart {
                    Text("T\(blockedByCart)")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                }
                if showsDayCategory, selected, let dayCategory {
                    categoryBadge(dayCategory)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: layout == .squareGrid4 ? nil : 48)
            .aspectRatio(layout == .squareGrid4 ? 1 : nil, contentMode: .fit)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(blockedByCart != nil)
    }

    private func categoryBadge(_ dayCategory: RoomDayCategory) -> some View {
        VStack(spacing: 2) {
            Text(dayCategory.shortTitle)
            if let dayCategoryTime {
                Text(Self.timeFormatter.string(from: dayCategoryTime))
                    .monospacedDigit()
            }
        }
        .font(.system(size: 10, weight: .black, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.58)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.black.opacity(0.22))
        .clipShape(Capsule())
    }

    private var foreground: Color {
        blockedByCart == nil ? (selected ? OceanKeyTheme.roomForeground : .white) : OceanKeyTheme.secondaryText.opacity(0.42)
    }

    private var background: Color {
        if blockedByCart != nil { return .black.opacity(0.10) }
        if selected, let dayCategory {
            return OceanKeyTheme.fill(for: dayCategory)
        }
        return selected ? OceanKeyTheme.accent : .black.opacity(0.20)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}
