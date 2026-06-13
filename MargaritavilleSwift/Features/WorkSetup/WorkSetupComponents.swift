import SwiftUI

struct WorkSetupHeader: View {
    let selectedCount: Int
    let canStart: Bool
    let onOpenSettings: () -> Void
    let onStart: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            settingsButton
            titleBlock
            Spacer()
            startButton
        }
        .padding(.horizontal, 14)
    }

    private var settingsButton: some View {
        Button(action: onOpenSettings) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 24, weight: .black))
                .frame(width: 54, height: 54)
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .background(OceanKeyTheme.surface.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Рабочий список")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
            Text("Выбрано: \(selectedCount)")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)
        }
    }

    private var startButton: some View {
        Button(action: onStart) {
            Text("Начать")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(canStart ? OceanKeyTheme.roomForeground : OceanKeyTheme.secondaryText.opacity(0.45))
                .padding(.horizontal, 18)
                .frame(height: 54)
                .background(canStart ? OceanKeyTheme.accent : OceanKeyTheme.surface.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canStart)
    }
}

struct HousekeeperWorkPicker: View {
    let housekeepers: [Housekeeper]
    let selectedIDs: Set<HousekeeperID>
    let focusedID: HousekeeperID?
    let onSelect: (Housekeeper) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(housekeepers) { housekeeper in
                    housekeeperButton(housekeeper)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func housekeeperButton(_ housekeeper: Housekeeper) -> some View {
        let isSelected = selectedIDs.contains(housekeeper.id)
        let isFocused = focusedID == housekeeper.id
        return Button {
            onSelect(housekeeper)
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(housekeeper.palette.color)
                    .frame(width: 14, height: 14)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.72), lineWidth: 1)
                    }
                Text(housekeeper.displayName)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .black))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 64)
            .foregroundStyle(isSelected ? OceanKeyTheme.roomForeground : .white)
            .background(isSelected ? housekeeper.palette.color : OceanKeyTheme.surface.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isFocused ? .white.opacity(0.82) : housekeeper.palette.color.opacity(0.34), lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
    }
}

struct CartSetupCard: View {
    let territory: Territory
    let selectedRooms: Set<RoomID>
    let blockedRooms: [RoomID: Int]
    let isFocused: Bool
    let territories: [Territory]
    let layout: HotelSummaryLayout
    let housekeeper: Housekeeper?
    let offTerritorySelectionGroups: [WorkSetupTerritorySelectionGroup]
    let onFocus: () -> Void
    let onRemove: () -> Void
    let onTerritoryChanged: (Territory) -> Void
    let onRoomToggle: (RoomID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            TerritoryPicker(
                territory: territory,
                territories: territories,
                onChanged: onTerritoryChanged
            )
            WorkSetupTerritorySelectionSummary(groups: offTerritorySelectionGroups)
            roomGrid
        }
        .padding(14)
        .background(OceanKeyTheme.surface.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isFocused ? OceanKeyTheme.accent.opacity(0.76) : OceanKeyTheme.accent.opacity(0.22), lineWidth: 1.5)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onFocus)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(housekeeper?.displayName ?? "Уборщица")
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                Text(territory.label)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText)
            }
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .black))
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.white)
                    .background(OceanKeyTheme.surface.opacity(0.74))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: 24, weight: .black, design: .rounded))
        .foregroundStyle(.white)
    }

    private var roomGrid: some View {
        LazyVGrid(columns: roomGridColumns, spacing: roomGridSpacing) {
            ForEach(visibleRooms, id: \.self) { room in
                RoomPickButton(
                    room: room,
                    selected: selectedRooms.contains(room),
                    blockedByCart: blockedRooms[room],
                    layout: layout,
                    dayCategory: nil,
                    dayCategoryTime: nil,
                    showsDayCategory: false,
                    onTap: { onRoomToggle(room) }
                )
            }
        }
    }

    private var visibleRooms: [RoomID] {
        territory.rooms
    }

    private var roomGridColumns: [GridItem] {
        switch layout {
        case .fullWidthBars:
            [GridItem(.adaptive(minimum: 66), spacing: 8)]
        case .squareGrid4:
            Array(repeating: GridItem(.flexible(minimum: 74), spacing: 10), count: 4)
        }
    }

    private var roomGridSpacing: CGFloat {
        switch layout {
        case .fullWidthBars:
            8
        case .squareGrid4:
            10
        }
    }
}

struct EmptySetupHint: View {
    var body: some View {
        Text("Выбери уборщицу сверху.")
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundStyle(OceanKeyTheme.secondaryText)
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(OceanKeyTheme.surface.opacity(0.70))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
