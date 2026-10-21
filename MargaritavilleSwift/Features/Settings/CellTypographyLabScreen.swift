import SwiftUI
import UIKit

struct CellTypographyLabScreen: View {
    let geometry: RoomCellGeometry
    let gridColumnCount: MargaritavilleGridColumnCount
    let statusPaletteSaturation: Double
    private let presetStore: CellTypographyPresetStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.interactionFeedback) private var feedback
    @State private var typography: RoomCellTypography
    @State private var savedPreset: SavedCellTypographyPreset?
    @State private var copiedPreset = false
    @State private var isDeleteConfirmationPresented = false

    init(
        geometry: RoomCellGeometry,
        gridColumnCount: MargaritavilleGridColumnCount,
        statusPaletteSaturation: Double,
        presetStore: CellTypographyPresetStore = CellTypographyPresetStore()
    ) {
        self.geometry = geometry
        self.gridColumnCount = gridColumnCount
        self.statusPaletteSaturation = statusPaletteSaturation
        self.presetStore = presetStore
        let savedPreset = presetStore.load()
        _savedPreset = State(initialValue: savedPreset)
        _typography = State(initialValue: savedPreset?.typography ?? .production)
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    previewPanel
                    typographyPanel(
                        title: "Основной номер",
                        size: $typography.roomNumberSize,
                        weight: $typography.roomNumberWeight,
                        offset: $typography.roomNumberVerticalOffset,
                        sizeRange: RoomCellTypography.roomNumberSizeRange
                    )
                    typographyPanel(
                        title: "Время активации",
                        size: $typography.activationTimeSize,
                        weight: $typography.activationTimeWeight,
                        offset: $typography.activationTimeVerticalOffset,
                        sizeRange: RoomCellTypography.activationTimeSizeRange
                    )
                    savePanel
                    if let savedPreset {
                        SavedCellTypographyPresetPanel(
                            preset: savedPreset,
                            copied: copiedPreset,
                            onCopy: copyPreset,
                            onDelete: { isDeleteConfirmationPresented = true }
                        )
                    }
                    resetButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("cellTypographyLab.screen")
        .confirmationDialog(
            "Удалить сохранённый пресет?",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Удалить пресет", role: .destructive, action: deletePreset)
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Текущие значения редактора останутся. Отменить удаление нельзя.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: dismissLab) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .black))
                    .frame(width: 48, height: 48)
                    .foregroundStyle(OceanKeyTheme.secondaryText)
                    .background(OceanKeyTheme.surface.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Назад в настройки")

            VStack(alignment: .leading, spacing: 2) {
                Text("Типографика ячеек")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Text("Только preview — основной экран не меняется")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
    }

    private var previewPanel: some View {
        CellTypographyLabPreview(
            geometry: geometry,
            gridColumnCount: gridColumnCount,
            typography: typography,
            statusPaletteSaturation: statusPaletteSaturation
        )
    }

    private var savePanel: some View {
        SettingsPanel(
            title: "Сохранение",
            subtitle: "Пресет хранится только для стенда и не меняет ячейки основного экрана."
        ) {
            Button(action: saveTypography) {
                Label("Сохранить настройки", systemImage: "square.and.arrow.down.fill")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .foregroundStyle(OceanKeyTheme.roomForeground)
                    .background(OceanKeyTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("cellTypographyLab.save")

            if let savedPreset {
                Label(
                    typography == savedPreset.typography ? "Сохранено" : "Есть несохранённые изменения",
                    systemImage: typography == savedPreset.typography ? "checkmark.circle.fill" : "circle.dotted"
                )
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(typography == savedPreset.typography ? .green : .orange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("cellTypographyLab.saveStatus")
            }
        }
    }

    private func typographyPanel(
        title: String,
        size: Binding<Double>,
        weight: Binding<RoomCellTypographyWeight>,
        offset: Binding<Double>,
        sizeRange: ClosedRange<Double>
    ) -> some View {
        SettingsPanel(title: title, subtitle: "Все значения применяются ко всем preview-ячейкам сразу.") {
            TypographySliderControl(
                title: "Размер",
                value: size,
                range: sizeRange,
                step: 1,
                valueLabel: "\(Int(size.wrappedValue.rounded())) pt"
            )
            TypographyWeightControl(selection: weight)
            TypographySliderControl(
                title: "Смещение по Y",
                value: offset,
                range: RoomCellTypography.verticalOffsetRange,
                step: 1,
                valueLabel: signedPoints(offset.wrappedValue)
            )
        }
    }

    private var resetButton: some View {
        Button(action: resetTypography) {
            VStack(spacing: 3) {
                Label("Сбросить редактор", systemImage: "arrow.counterclockwise.circle.fill")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                Text("Сохранённый пресет останется")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity, minHeight: 58)
            .foregroundStyle(typography == .production ? OceanKeyTheme.secondaryText.opacity(0.48) : OceanKeyTheme.roomForeground)
            .background(typography == .production ? OceanKeyTheme.surface.opacity(0.84) : OceanKeyTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(typography == .production)
        .accessibilityIdentifier("cellTypographyLab.reset")
    }

    private func dismissLab() {
        feedback.tap()
        dismiss()
    }

    private func resetTypography() {
        typography = .production
        feedback.confirm()
    }

    private func saveTypography() {
        guard let preset = try? presetStore.save(typography) else { return }
        savedPreset = preset
        copiedPreset = false
        feedback.confirm()
    }

    private func copyPreset() {
        guard let savedPreset,
              let json = try? CellTypographyPresetStore.exportJSON(savedPreset) else { return }
        UIPasteboard.general.string = json
        copiedPreset = true
        feedback.confirm()
    }

    private func deletePreset() {
        presetStore.delete()
        savedPreset = nil
        copiedPreset = false
        feedback.deselect()
    }

    private func signedPoints(_ value: Double) -> String {
        let rounded = Int(value.rounded())
        return rounded > 0 ? "+\(rounded) pt" : "\(rounded) pt"
    }
}

private struct TypographySliderControl: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let valueLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(valueLabel).foregroundStyle(OceanKeyTheme.secondaryText)
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))

            Slider(value: $value, in: range, step: step)
                .tint(OceanKeyTheme.accent)
                .accessibilityValue(valueLabel)
        }
        .padding(12)
        .background(OceanKeyTheme.surface.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct TypographyWeightControl: View {
    @Binding var selection: RoomCellTypographyWeight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Толщина")
                Spacer()
                Text(selection.title).foregroundStyle(OceanKeyTheme.secondaryText)
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))

            Picker("Толщина", selection: $selection) {
                ForEach(RoomCellTypographyWeight.allCases) { weight in
                    Text(weight.title).tag(weight)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(12)
        .background(OceanKeyTheme.surface.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
