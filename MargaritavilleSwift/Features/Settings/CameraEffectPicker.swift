import SwiftUI

/// Выбор эффекта камеры в два шага: строка категорий, под ней — эффекты
/// выбранной категории кнопками.
struct CameraEffectPicker: View {
    @Binding var effect: CameraBackgroundEffect
    @Environment(\.interactionFeedback) private var feedback
    @State private var category: CameraEffectCategory?

    private var shownCategory: CameraEffectCategory { category ?? effect.category }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CameraEffectCategory.allCases) { item in
                        categoryChip(item)
                    }
                }
                .padding(.vertical, 2)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
                ForEach(shownCategory.effects) { item in
                    effectButton(item)
                }
            }
        }
    }

    private func categoryChip(_ item: CameraEffectCategory) -> some View {
        let isSelected = item == shownCategory
        return Button {
            category = item
            feedback.confirm()
        } label: {
            Label(item.title, systemImage: item.systemImage)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .padding(.horizontal, 12)
                .frame(minHeight: 36)
                .foregroundStyle(isSelected ? Color.black : OceanKeyTheme.secondaryText)
                .background(isSelected ? OceanKeyTheme.accent : Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func effectButton(_ item: CameraBackgroundEffect) -> some View {
        let isSelected = item == effect
        return Button {
            effect = item
            feedback.confirm()
        } label: {
            Text(item.title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 6)
                .foregroundStyle(isSelected ? OceanKeyTheme.accent : Color.white)
                .background(isSelected ? OceanKeyTheme.accent.opacity(0.16) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? OceanKeyTheme.accent : Color.white.opacity(0.1), lineWidth: isSelected ? 1.5 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
