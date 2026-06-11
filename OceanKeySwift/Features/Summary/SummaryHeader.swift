import SwiftUI

struct SummaryHeader: View {
    struct StatusChip: Identifiable, Equatable {
        let status: RoomStatus
        let count: Int
        let usesPurpleScheduled: Bool

        var id: RoomStatus { status }
    }

    let counts: SummaryCounts
    var progressLabel: String?
    var statusChips: [StatusChip] = []
    @Binding var personalCartMarkers: PersonalCartMarkers
    let onOpenSettings: () -> Void
    let onOpenSelection: () -> Void
    @Environment(\.interactionFeedback) private var feedback
    @State private var selectionPuzzleProgress: CGFloat = 0
    @State private var activePersonalCartMarkerSlot: PersonalCartMarkerSlot?

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 8) {
                softButton(systemName: "line.3.horizontal", action: onOpenSettings)
                    .opacity(CGFloat(1) - min(selectionPuzzleProgress * CGFloat(1.65), CGFloat(1)))

                PersonalCartMarkerStrip(
                    markers: personalCartMarkers,
                    building: .a,
                    onTap: openPersonalCartMarkerPicker
                )

                Spacer(minLength: 6)

                centerStats

                PersonalCartMarkerStrip(
                    markers: personalCartMarkers,
                    building: .b,
                    onTap: openPersonalCartMarkerPicker
                )

                Spacer(minLength: 94)
            }
            .padding(.leading, 18)
            .padding(.trailing, 10)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .overlay {
                SummarySelectionPuzzleHandle(
                    progress: $selectionPuzzleProgress,
                    onComplete: onOpenSelection
                )
            }
        }
        .frame(height: 48)
        .confirmationDialog(
            activePersonalCartMarkerSlot?.title ?? "Метка тележки",
            isPresented: Binding(
                get: { activePersonalCartMarkerSlot != nil },
                set: { if !$0 { activePersonalCartMarkerSlot = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let slot = activePersonalCartMarkerSlot {
                ForEach(PersonalCartMarkers.allowedFloors, id: \.self) { floor in
                    Button(floorPickerTitle(floor, for: slot)) {
                        setPersonalCartMarkerFloor(floor, for: slot)
                    }
                }
                Button(clearPickerTitle(for: slot), role: .destructive) {
                    setPersonalCartMarkerFloor(nil, for: slot)
                }
            }
        } message: {
            if let slot = activePersonalCartMarkerSlot {
                Text("Выбери этаж для \(slot.title) метки здания \(slot.building.label).")
            }
        }
    }

    private func softButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .black))
                .frame(width: 48, height: 48)
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .background(.black.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(OceanKeyTheme.accent.opacity(0.16), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var centerStats: some View {
        if let progressLabel, !statusChips.isEmpty {
            HStack(spacing: 6) {
                Text(progressLabel)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                ForEach(statusChips) { chip in
                    Text("\(chip.count)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.black)
                        .frame(minWidth: 24, minHeight: 22)
                        .background(OceanKeyTheme.fill(
                            for: chip.status,
                            usesPurpleScheduled: chip.usesPurpleScheduled
                        ))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.62)
        } else {
            HStack(spacing: 12) {
                Text("\(counts.total)").foregroundStyle(OceanKeyTheme.pending)
                Text("\(counts.completed)").foregroundStyle(OceanKeyTheme.ready)
                Text("\(counts.remaining)").foregroundStyle(Color(hex: 0xFF4A4A))
            }
            .font(.system(size: 22, weight: .black, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
    }

    private func openPersonalCartMarkerPicker(_ slot: PersonalCartMarkerSlot) {
        feedback.tap()
        activePersonalCartMarkerSlot = slot
    }

    private func setPersonalCartMarkerFloor(_ floor: Int?, for slot: PersonalCartMarkerSlot) {
        feedback.confirm()
        personalCartMarkers = personalCartMarkers.settingFloor(floor, for: slot)
        activePersonalCartMarkerSlot = nil
    }

    private func floorPickerTitle(_ floor: Int, for slot: PersonalCartMarkerSlot) -> String {
        let prefix = personalCartMarkers.floor(for: slot) == floor ? "✓ " : ""
        return "\(prefix)Этаж \(floor)"
    }

    private func clearPickerTitle(for slot: PersonalCartMarkerSlot) -> String {
        let prefix = personalCartMarkers.floor(for: slot) == nil ? "✓ " : ""
        return "\(prefix)Очистить"
    }
}

#Preview {
    @Previewable @State var markers = PersonalCartMarkers(
        aYellowFloor: 3,
        aGrayFloor: nil,
        bYellowFloor: 5,
        bGrayFloor: 2
    )
    SummaryHeader(
        counts: SummaryCounts(total: 10, completed: 10, remaining: 0),
        personalCartMarkers: $markers,
        onOpenSettings: {},
        onOpenSelection: {}
    )
        .background(OceanKeyTheme.background)
}
