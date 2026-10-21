import SwiftUI

struct CellTypographyLabPreview: View {
    let geometry: RoomCellGeometry
    let gridColumnCount: MargaritavilleGridColumnCount
    let typography: RoomCellTypography
    let statusPaletteSaturation: Double

    @Namespace private var regularNamespace
    @Namespace private var pulseNamespace
    @Namespace private var vipJellyNamespace
    @Namespace private var vipHDRNamespace
    @Namespace private var vipCombinedNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Production-ячейки")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("То же выбранное число колонок, размеры и геометрия, что на главном экране. Все варианты используют production-модель и эффекты.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 2)

            previewGroup(title: "Обычные статусы") {
                grid(rooms: CellTypographyLabFixtures.regularRooms, namespace: regularNamespace)
            }

            previewGroup(title: "HDR-всплеск + rubber") {
                CellTypographyLabPulseGrid(
                    geometry: geometry,
                    gridColumnCount: gridColumnCount,
                    typography: typography,
                    statusPaletteSaturation: statusPaletteSaturation,
                    rooms: CellTypographyLabFixtures.regularRooms,
                    namespace: pulseNamespace
                )
            }

            previewGroup(title: "VIP-желе") {
                grid(rooms: CellTypographyLabFixtures.vipRooms, namespace: vipJellyNamespace)
                    .environment(\.experimentalVIPJellyEnabled, true)
                    .environment(\.experimentalVIPHDREnabled, false)
            }

            previewGroup(title: "VIP HDR") {
                grid(rooms: CellTypographyLabFixtures.vipRooms, namespace: vipHDRNamespace)
                    .environment(\.experimentalVIPJellyEnabled, false)
                    .environment(\.experimentalVIPHDREnabled, true)
            }

            previewGroup(title: "VIP-желе + HDR") {
                grid(rooms: CellTypographyLabFixtures.vipRooms, namespace: vipCombinedNamespace)
                    .environment(\.experimentalVIPJellyEnabled, true)
                    .environment(\.experimentalVIPHDREnabled, true)
            }
        }
    }

    private func previewGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .padding(.horizontal, 2)
            content()
        }
    }

    private func grid(
        rooms: [RoomCell],
        namespace: Namespace.ID
    ) -> some View {
        MargaritavilleRoomGrid(
            rooms,
            geometry: geometry,
            columnCount: gridColumnCount
        ) { room in
            previewTile(room: room, namespace: namespace, pulseEvent: nil)
        }
        .padding(.horizontal, -18)
    }

    fileprivate func previewTile(
        room: RoomCell,
        namespace: Namespace.ID,
        pulseEvent: RoomStatusHDRPulseEvent?
    ) -> some View {
        MargaritavilleRoomTile(
            room: room,
            geometry: geometry,
            typography: typography,
            isZoomed: false,
            zoomNamespace: namespace,
            statusPaletteSaturation: statusPaletteSaturation,
            statusHDRPulseEvent: pulseEvent,
            onZoom: {},
            onAdvance: {},
            onOpenDetails: { _ in },
            onVIPToggle: {},
            onReset: {},
            onSchedule: {}
        )
        .allowsHitTesting(false)
        .accessibilityIdentifier("cellTypographyLab.preview.\(room.id)")
    }
}

private struct CellTypographyLabPulseGrid: View {
    let geometry: RoomCellGeometry
    let gridColumnCount: MargaritavilleGridColumnCount
    let typography: RoomCellTypography
    let statusPaletteSaturation: Double
    let rooms: [RoomCell]
    let namespace: Namespace.ID

    @State private var generation = 0
    @State private var startedAt = Date()

    var body: some View {
        MargaritavilleRoomGrid(
            rooms,
            geometry: geometry,
            columnCount: gridColumnCount
        ) { room in
            MargaritavilleRoomTile(
                room: room,
                geometry: geometry,
                typography: typography,
                isZoomed: false,
                zoomNamespace: namespace,
                statusPaletteSaturation: statusPaletteSaturation,
                statusHDRPulseEvent: RoomStatusHDRPulseEvent(
                    generation: generation,
                    status: room.status(in: .simpleCycle),
                    startedAt: startedAt
                ),
                onZoom: {},
                onAdvance: {},
                onOpenDetails: { _ in },
                onVIPToggle: {},
                onReset: {},
                onSchedule: {}
            )
            .allowsHitTesting(false)
            .accessibilityIdentifier("cellTypographyLab.pulse.\(room.id)")
        }
        .padding(.horizontal, -18)
        .environment(\.experimentalStatusHDRPulseEnabled, true)
        .task {
            while !Task.isCancelled {
                startedAt = Date()
                generation += 1
                try? await Task.sleep(for: .milliseconds(3_250))
            }
        }
    }
}

enum CellTypographyLabFixtures {
    private static let base = Date(timeIntervalSince1970: 1_788_780_600)

    static let regularRooms = RoomStatus.allCases.compactMap { fixture(for: $0, isVIP: false) }
    static let vipRooms = RoomStatus.allCases.compactMap { fixture(for: $0, isVIP: true) }

    private static func fixture(for status: RoomStatus, isVIP: Bool) -> RoomCell? {
        let room: RoomCell
        switch status {
        case .pending:
            room = RoomCell(id: "101", opened: false, completedTasks: [], isVIP: isVIP)
        case .open:
            room = RoomCell(
                id: "218",
                opened: true,
                completedTasks: [],
                isVIP: isVIP,
                statusChangedAt: base.addingTimeInterval(900)
            )
        case .inProgress:
            room = RoomCell(
                id: "254",
                opened: true,
                completedTasks: [.stripped],
                isVIP: isVIP,
                statusChangedAt: base.addingTimeInterval(1_350)
            )
        case .ready:
            room = RoomCell(
                id: "307",
                opened: true,
                completedTasks: Set(RoomTask.allCases),
                isVIP: isVIP,
                statusChangedAt: base.addingTimeInterval(1_800)
            )
        case .scheduled:
            room = RoomCell(
                id: "412",
                opened: false,
                completedTasks: [],
                isVIP: isVIP,
                scheduledTime: base.addingTimeInterval(2_700)
            )
        }

        var resolvedRoom = room
        if status == .pending {
            resolvedRoom.timeline.selectedAt = base
        }
        return resolvedRoom.status(in: .simpleCycle) == status ? resolvedRoom : nil
    }
}
