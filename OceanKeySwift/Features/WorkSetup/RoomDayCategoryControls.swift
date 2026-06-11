import SwiftUI

struct RoomDayCategoryControls: View {
    let activeCategory: RoomDayCategory
    let filter: RoomDayCategory?
    let appliesTime: Bool
    let timeSelection: RoomScheduleSelection
    let onActiveChanged: (RoomDayCategory) -> Void
    let onFilterChanged: (RoomDayCategory?) -> Void
    let onAppliesTimeChanged: (Bool) -> Void
    let onTimeSelectionChanged: (RoomScheduleSelection) -> Void

    @Environment(\.interactionFeedback) private var feedback

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Категория")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)
            categoryChips
            timeControls
            filterRow
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RoomDayCategory.allCases) { category in
                    Button {
                        feedback.tap()
                        onActiveChanged(category)
                    } label: {
                        Text(category.title)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .frame(height: 38)
                            .foregroundStyle(.black)
                            .background(
                                OceanKeyTheme.fill(for: category)
                                    .opacity(activeCategory == category ? 1 : 0.48)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(activeCategory == category ? .white.opacity(0.72) : .clear, lineWidth: 1.5)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var timeControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                feedback.tap()
                onAppliesTimeChanged(!appliesTime)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: appliesTime ? "clock.fill" : "clock")
                    Text(appliesTime ? timeSelection.displayLabel : "Без времени")
                    Spacer()
                    Text("15 мин")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(OceanKeyTheme.secondaryText)
                }
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(appliesTime ? OceanKeyTheme.roomForeground : .white)
                .padding(.horizontal, 11)
                .frame(height: 38)
                .background(appliesTime ? OceanKeyTheme.scheduled : .black.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            if appliesTime {
                HStack(spacing: 8) {
                    compactPicker(values: RoomScheduleSelection.hours, selection: timeSelection.hour) { value in
                        var next = timeSelection
                        next.hour = value
                        onTimeSelectionChanged(next)
                    } label: { "\($0)" }
                    compactPicker(values: RoomScheduleSelection.minutes, selection: timeSelection.minute) { value in
                        var next = timeSelection
                        next.minute = value
                        onTimeSelectionChanged(next)
                    } label: { String(format: "%02d", $0) }
                    periodPicker
                }
            }
        }
    }

    private var periodPicker: some View {
        HStack(spacing: 6) {
            ForEach(RoomSchedulePeriod.allCases) { period in
                Button {
                    feedback.tap()
                    var next = timeSelection
                    next.period = period
                    onTimeSelectionChanged(next)
                } label: {
                    Text(period.label)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .foregroundStyle(timeSelection.period == period ? OceanKeyTheme.roomForeground : .white)
                        .background(timeSelection.period == period ? OceanKeyTheme.scheduled : .black.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var filterRow: some View {
        HStack(spacing: 8) {
            filterChip("Все", selected: filter == nil) {
                onFilterChanged(nil)
            }
            ForEach(RoomDayCategory.allCases) { category in
                filterChip(category.shortTitle, selected: filter == category) {
                    onFilterChanged(category)
                }
            }
        }
    }

    private func compactPicker(
        values: [Int],
        selection: Int,
        onChanged: @escaping (Int) -> Void,
        label: @escaping (Int) -> String
    ) -> some View {
        Menu {
            ForEach(values, id: \.self) { value in
                Button(label(value)) {
                    feedback.tap()
                    onChanged(value)
                }
            }
        } label: {
            Text(label(selection))
                .font(.system(size: 14, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .foregroundStyle(OceanKeyTheme.roomForeground)
                .background(OceanKeyTheme.scheduled)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            feedback.tap()
            action()
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .frame(minWidth: 38)
                .padding(.vertical, 8)
                .foregroundStyle(selected ? OceanKeyTheme.roomForeground : .white)
                .background(selected ? OceanKeyTheme.secondaryText : .black.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
