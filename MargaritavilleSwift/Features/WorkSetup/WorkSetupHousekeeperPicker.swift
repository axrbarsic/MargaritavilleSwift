import SwiftUI

struct WorkSetupHousekeeperPickerRoute: Identifiable {
    let cartNumber: Int
    var id: Int { cartNumber }
}

struct HousekeeperAssignmentButton: View {
    let housekeeper: Housekeeper?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(housekeeper?.palette.color ?? OceanKeyTheme.accent.opacity(0.45))
                    .frame(width: 18, height: 18)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.72), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(housekeeper?.displayName ?? "Выбрать уборщицу")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                    Text("Имя для этой тележки")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(OceanKeyTheme.secondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(housekeeper?.palette.color ?? OceanKeyTheme.secondaryText)
            }
            .frame(minHeight: 60)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(OceanKeyTheme.surface.opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke((housekeeper?.palette.color ?? OceanKeyTheme.accent).opacity(0.45), lineWidth: 1.4)
            }
        }
        .buttonStyle(.plain)
    }
}

struct WorkSetupHousekeeperPickerSheet: View {
    let cartNumber: Int
    let housekeepers: [Housekeeper]
    let selectedID: HousekeeperID?
    let onSelect: (HousekeeperID) -> Void
    let onClear: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(housekeepers) { housekeeper in
                            housekeeperButton(housekeeper)
                        }
                    }
                    clearButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Тележка \(cartNumber)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText)
                Text("Уборщица")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .black))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(.white)
                    .background(OceanKeyTheme.surface.opacity(0.84))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func housekeeperButton(_ housekeeper: Housekeeper) -> some View {
        let isSelected = selectedID == housekeeper.id
        return Button {
            onSelect(housekeeper.id)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(housekeeper.palette.color)
                        .frame(width: 18, height: 18)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(.white)
                    }
                }
                Text(housekeeper.displayName)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(isSelected ? OceanKeyTheme.roomForeground : .white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 82)
            .padding(12)
            .background(isSelected ? housekeeper.palette.color : OceanKeyTheme.surface.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? .white.opacity(0.78) : housekeeper.palette.color.opacity(0.42), lineWidth: 1.3)
            }
        }
        .buttonStyle(.plain)
    }

    private var clearButton: some View {
        Button(action: onClear) {
            HStack {
                Image(systemName: "person.crop.circle.badge.xmark")
                    .font(.system(size: 20, weight: .black))
                Text("Без имени")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                Spacer()
            }
            .foregroundStyle(OceanKeyTheme.secondaryText)
            .frame(minHeight: 54)
            .padding(.horizontal, 14)
            .background(OceanKeyTheme.surface.opacity(0.68))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
