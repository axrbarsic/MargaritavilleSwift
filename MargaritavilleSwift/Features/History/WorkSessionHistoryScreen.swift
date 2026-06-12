import SwiftUI

struct WorkSessionHistoryScreen: View {
    let entries: [WorkSessionHistoryEntry]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                OceanKeyTheme.background.ignoresSafeArea()

                if entries.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(entries) { entry in
                                WorkSessionHistoryCard(entry: entry)
                            }
                        }
                        .padding(16)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Хронология")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                        .font(.system(size: 17, weight: .black, design: .rounded))
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 42, weight: .black))
                .foregroundStyle(OceanKeyTheme.accent)

            Text("История пока пустая")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Она начнёт заполняться после изменений ячеек, тележек, заметок, VIP, времени и медиа.")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
    }
}

private struct WorkSessionHistoryCard: View {
    let entry: WorkSessionHistoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .black))
                    .frame(width: 36, height: 36)
                    .foregroundStyle(OceanKeyTheme.accent)
                    .background(OceanKeyTheme.accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(entry.happenedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(OceanKeyTheme.secondaryText)
                }

                Spacer(minLength: 8)
            }

            HistorySnapshotPreview(entry: entry)
        }
        .padding(14)
        .background(OceanKeyTheme.surface.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(OceanKeyTheme.accent.opacity(0.18), lineWidth: 1)
        }
    }

    private var iconName: String {
        switch entry.kind {
        case .roomOpened, .scheduledRoomAutoOpened: "door.left.hand.open"
        case .roomClosed: "door.left.hand.closed"
        case .roomStatusChanged: "paintpalette.fill"
        case .roomTaskChanged: "checklist"
        case .roomVIPChanged: "star.fill"
        case .roomScheduleChanged: "clock.fill"
        case .roomDayCategoryChanged: "tag.fill"
        case .roomTextNoteChanged, .cartNoteChanged: "note.text"
        case .roomVoiceTranscriptChanged: "mic.fill"
        case .roomMediaAdded, .cartMediaAdded: "camera.fill"
        case .cartConsumablesChanged: "shippingbox.fill"
        case .selectionChanged: "rectangle.grid.2x2.fill"
        case .workdayLocked: "lock.fill"
        case .workdayUnlocked: "lock.open.fill"
        }
    }
}

private struct HistorySnapshotPreview: View {
    let entry: WorkSessionHistoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 10) {
                countPill("\(entry.snapshot.counts.total)", color: .yellow)
                countPill("\(entry.snapshot.counts.completed)", color: OceanKeyTheme.accent)
                countPill("\(entry.snapshot.counts.remaining)", color: OceanKeyTheme.open)
                Spacer()
            }

            ForEach(entry.snapshot.carts) { cart in
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Тележка \(cart.id)")
                        Spacer()
                        Text(cart.building)
                    }
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                    ForEach(cart.rooms) { room in
                        HistoryRoomPreviewCell(
                            room: room,
                            isHighlighted: entry.roomID == room.id
                        )
                    }
                }
            }
        }
        .padding(10)
        .background(.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func countPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .black, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(color)
    }
}

private struct HistoryRoomPreviewCell: View {
    let room: RoomCell
    let isHighlighted: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(room.id)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(RoomTask.allCases) { task in
                Text(task.rawValue)
                    .opacity(room.completedTasks.contains(task) ? 1 : 0.35)
            }
        }
        .font(.system(size: 18, weight: .black, design: .rounded))
        .foregroundStyle(OceanKeyTheme.roomForeground)
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(OceanKeyTheme.fill(for: room.status))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(isHighlighted ? .white : .clear, lineWidth: 2)
        }
    }
}

#Preview {
    WorkSessionHistoryScreen(entries: WorkSessionStore.preview().history)
        .preferredColorScheme(.dark)
}
