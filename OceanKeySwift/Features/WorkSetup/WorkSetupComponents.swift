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
            ForEach(territory.rooms, id: \.self) { room in
                RoomPickButton(
                    room: room,
                    selected: selectedRooms.contains(room),
                    blockedByCart: blockedRooms[room],
                    layout: layout,
                    onTap: { onRoomToggle(room) }
                )
            }
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

struct TerritoryPicker: View {
    let territory: Territory
    let territories: [Territory]
    let onChanged: (Territory) -> Void

    private var buildings: [Building] {
        Array(Set(territories.map(\.building))).sorted { $0.label < $1.label }
    }

    private var floors: [Int] {
        Array(Set(territories.map(\.floor))).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                ForEach(buildings, id: \.self) { building in
                    pickerChip(
                        building.label,
                        selected: territory.building == building,
                        action: { update(building: building, floor: territory.floor) }
                    )
                }
            }

            HStack(spacing: 8) {
                ForEach(floors, id: \.self) { floor in
                    pickerChip(
                        "\(floor)",
                        selected: territory.floor == floor,
                        action: { update(building: territory.building, floor: floor) }
                    )
                }
            }
        }
    }

    private func update(building: Building, floor: Int) {
        if let next = territories.first(where: { $0.building == building && $0.floor == floor }) {
            onChanged(next)
        }
    }

    private func pickerChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .frame(minWidth: 46)
                .padding(.vertical, 10)
                .foregroundStyle(selected ? OceanKeyTheme.roomForeground : .white)
                .background(selected ? OceanKeyTheme.accent : .black.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct RoomPickButton: View {
    let room: RoomID
    let selected: Bool
    let blockedByCart: Int?
    let layout: HotelSummaryLayout
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(RoomCatalog.displayRoomID(room, compactLetteredLabels: true))
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .monospacedDigit()
                if let blockedByCart {
                    Text("T\(blockedByCart)")
                        .font(.system(size: 9, weight: .black, design: .rounded))
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

    private var foreground: Color {
        blockedByCart == nil ? (selected ? OceanKeyTheme.roomForeground : .white) : OceanKeyTheme.secondaryText.opacity(0.42)
    }

    private var background: Color {
        if blockedByCart != nil { return .black.opacity(0.10) }
        return selected ? OceanKeyTheme.accent : .black.opacity(0.20)
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
