import SwiftUI

struct RoomDayCategoryControls: View {
    let activeCategory: RoomDayCategory
    let filter: RoomDayCategory?
    let activeTimePreset: RoomDayCategoryTimePreset?
    let categoryCounts: RoomDayCategoryCounts
    let onActiveChanged: (RoomDayCategory) -> Void
    let onFilterChanged: (RoomDayCategory?) -> Void
    let onTimePresetChanged: (RoomDayCategoryTimePreset?) -> Void

    @Environment(\.interactionFeedback) private var feedback

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Категория")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)
            categoryChips
            if activeCategory == .dueOut {
                timeControls
            }
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
                        categoryLabel(category, selected: activeCategory == category)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var timeControls: some View {
        HStack(spacing: 8) {
            timeChip("Без времени", selected: activeTimePreset == nil) {
                onTimePresetChanged(nil)
            }
            ForEach(RoomDayCategoryTimePreset.allCases) { preset in
                timeChip(preset.title, selected: activeTimePreset == preset) {
                    onTimePresetChanged(preset)
                }
            }
        }
    }

    private var filterRow: some View {
        HStack(spacing: 8) {
            filterChip("Все", selected: filter == nil) {
                onFilterChanged(nil)
            }
            ForEach(RoomDayCategory.allCases) { category in
                filterChip("\(category.shortTitle) \(categoryCounts[category])", selected: filter == category) {
                    onFilterChanged(category)
                }
            }
        }
    }

    private func categoryLabel(_ category: RoomDayCategory, selected: Bool) -> some View {
        HStack(spacing: 7) {
            Text(category.title)
                .lineLimit(1)
            Text("\(categoryCounts[category])")
                .monospacedDigit()
                .font(.system(size: 12, weight: .black, design: .rounded))
                .padding(.horizontal, 7)
                .frame(height: 22)
                .background(Color.black.opacity(0.22))
                .clipShape(Capsule())
        }
        .font(.system(size: 14, weight: .black, design: .rounded))
        .padding(.horizontal, 12)
        .frame(height: 38)
        .foregroundStyle(.black)
        .background(
            OceanKeyTheme.fill(for: category)
                .opacity(selected ? 1 : 0.48)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(selected ? .white.opacity(0.72) : .clear, lineWidth: 1.5)
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

    private func timeChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            feedback.tap()
            action()
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .foregroundStyle(selected ? OceanKeyTheme.roomForeground : .white)
                .background(selected ? OceanKeyTheme.scheduled : .black.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
