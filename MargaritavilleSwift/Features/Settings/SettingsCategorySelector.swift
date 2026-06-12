import SwiftUI

struct SettingsCategorySelector: View {
    @Binding var selectedCategory: SettingsCategory

    var body: some View {
        ScrollView(.horizontal) {
            LazyHGrid(rows: [GridItem(.fixed(46)), GridItem(.fixed(46))], spacing: 8) {
                ForEach(SettingsCategory.allCases) { category in
                    SettingsCategoryButton(
                        category: category,
                        isSelected: category == selectedCategory,
                        onSelect: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, 1)
        }
        .scrollIndicators(.hidden)
    }
}

private struct SettingsCategoryButton: View {
    let category: SettingsCategory
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Label(category.title, systemImage: category.iconName)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(isSelected ? OceanKeyTheme.roomForeground : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, 15)
                .frame(minWidth: 138, maxWidth: 178, minHeight: 46)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(OceanKeyTheme.accent.opacity(isSelected ? 0 : 0.22), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var background: Color {
        isSelected ? OceanKeyTheme.accent : OceanKeyTheme.surface.opacity(0.82)
    }
}

#Preview {
    @Previewable @State var category = SettingsCategory.appearance
    SettingsCategorySelector(selectedCategory: $category)
        .padding()
        .background(OceanKeyTheme.background)
        .preferredColorScheme(.dark)
}
