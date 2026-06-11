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

struct CartNumberPicker: View {
    let selectedCarts: Set<Int>
    @Binding var focusedCart: Int
    let onToggleCart: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(Array(WorkSessionSelectionRules.cartRange), id: \.self) { cartNumber in
                    cartButton(cartNumber)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func cartButton(_ cartNumber: Int) -> some View {
        Button {
            onToggleCart(cartNumber)
        } label: {
            Text("\(cartNumber)")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .monospacedDigit()
                .frame(width: 48, height: 48)
                .foregroundStyle(selectedCarts.contains(cartNumber) ? OceanKeyTheme.roomForeground : .white)
                .background(selectedCarts.contains(cartNumber) ? OceanKeyTheme.accent : OceanKeyTheme.surface.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(focusedCart == cartNumber ? .white.opacity(0.74) : OceanKeyTheme.accent.opacity(0.20), lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
    }
}

struct CartSetupCard: View {
    let cartNumber: Int
    let territory: Territory
    let selectedRooms: Set<RoomID>
    let blockedRooms: [RoomID: Int]
    let isFocused: Bool
    let territories: [Territory]
    let layout: HotelSummaryLayout
    let dayCategoriesEnabled: Bool
    let activeDayCategory: RoomDayCategory
    let dayCategoryFilter: RoomDayCategory?
    let dayCategoryTimePreset: RoomDayCategoryTimePreset?
    let dayCategoryCounts: RoomDayCategoryCounts
    let offTerritorySelectionGroups: [WorkSetupTerritorySelectionGroup]
    let roomCategory: (RoomID) -> RoomDayCategory?
    let roomCategoryTime: (RoomID) -> Date?
    let onActiveDayCategoryChanged: (RoomDayCategory) -> Void
    let onDayCategoryFilterChanged: (RoomDayCategory?) -> Void
    let onDayCategoryTimePresetChanged: (RoomDayCategoryTimePreset?) -> Void
    let onFocus: () -> Void
    let onTerritoryChanged: (Territory) -> Void
    let onRoomToggle: (RoomID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            header
            TerritoryPicker(
                territory: territory,
                territories: territories,
                onChanged: onTerritoryChanged
            )
            WorkSetupTerritorySelectionSummary(groups: offTerritorySelectionGroups)
            if dayCategoriesEnabled {
                RoomDayCategoryControls(
                    activeCategory: activeDayCategory,
                    filter: dayCategoryFilter,
                    activeTimePreset: dayCategoryTimePreset,
                    categoryCounts: dayCategoryCounts,
                    onActiveChanged: onActiveDayCategoryChanged,
                    onFilterChanged: onDayCategoryFilterChanged,
                    onTimePresetChanged: onDayCategoryTimePresetChanged
                )
            }
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
        HStack(alignment: .firstTextBaseline) {
            Text("Тележка \(cartNumber)")
            Spacer()
            Text(territory.label)
        }
        .font(.system(size: 24, weight: .black, design: .rounded))
        .foregroundStyle(.white)
    }

    private var roomGrid: some View {
        LazyVGrid(columns: roomGridColumns, spacing: 8) {
            ForEach(visibleRooms, id: \.self) { room in
                RoomPickButton(
                    room: room,
                    selected: selectedRooms.contains(room),
                    blockedByCart: blockedRooms[room],
                    layout: layout,
                    dayCategory: roomCategory(room),
                    dayCategoryTime: roomCategoryTime(room),
                    showsDayCategory: dayCategoriesEnabled,
                    onTap: { onRoomToggle(room) }
                )
            }
        }
    }

    private var visibleRooms: [RoomID] {
        guard let dayCategoryFilter else { return territory.rooms }
        return territory.rooms.filter { room in
            selectedRooms.contains(room) && roomCategory(room) == dayCategoryFilter
        }
    }

    private var roomGridColumns: [GridItem] {
        switch layout {
        case .fullWidthBars:
            [GridItem(.adaptive(minimum: 66), spacing: 8)]
        case .squareGrid4:
            Array(repeating: GridItem(.flexible(minimum: 44), spacing: 8), count: 4)
        }
    }
}

struct EmptySetupHint: View {
    var body: some View {
        Text("Выбери одну или несколько тележек сверху.")
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundStyle(OceanKeyTheme.secondaryText)
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(OceanKeyTheme.surface.opacity(0.70))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
