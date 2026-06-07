import CoreTransferable
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct SettingsScreen: View {
    @Bindable var workSession: WorkSessionStore
    @Bindable var appSettings: AppSettingsStore
    @Bindable var performanceTelemetry: PerformanceTelemetryStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.interactionFeedback) private var feedback
    @State private var selectedCategory: SettingsCategory = .appearance
    @State private var isChangelogPresented = false
    @State private var isHistoryPresented = false
    @State private var isResetConfirmationPresented = false
    @State private var selectedBackgroundVideoItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    SettingsCategorySelector(selectedCategory: $selectedCategory)
                        .onChange(of: selectedCategory) { _, _ in
                            feedback.tap()
                        }
                    selectedCategoryContent
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $isChangelogPresented) {
            BuildChangelogScreen()
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $isHistoryPresented) {
            WorkSessionHistoryScreen(entries: workSession.history)
                .preferredColorScheme(.dark)
        }
        .confirmationDialog(
            "Сбросить настройки?",
            isPresented: $isResetConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Сбросить", role: .destructive, action: resetSettings)
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Размер ячеек, режимы меню, палитра и Matrix-настройки вернутся к значениям по умолчанию.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .black))
                    .frame(width: 48, height: 48)
                    .foregroundStyle(OceanKeyTheme.secondaryText)
                    .background(OceanKeyTheme.surface.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Text("Настройки")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
    }

    @ViewBuilder
    private var selectedCategoryContent: some View {
        switch selectedCategory {
        case .appearance:
            appearanceSection
            backgroundSection
            settingsSection
        case .workflow:
            workSection
        case .data:
            storageSection
            migrationSection
        case .developer:
            developerSection
        }
    }

    private var developerSection: some View {
        SettingsPanel(title: "Разработчик") {
            SettingsInfoRow(title: "Версия", value: AppBuildInfo.versionLabel, systemName: "number")
            Button(action: openChangelog) {
                SettingsInfoRow(title: "Что изменилось", value: "Открыть", systemName: "list.bullet.clipboard.fill")
            }
            .buttonStyle(.plain)
            SettingsInfoRow(title: "Движок", value: "SpriteKit + SwiftUI", systemName: "sparkles")
            SettingsInfoRow(title: "Цель", value: "Физический iPhone", systemName: "iphone")
            SettingsInfoRow(title: "ProMotion", value: RuntimeDiagnostics.currentProMotionStatusLabel(), systemName: "display")
            SettingsInfoRow(title: "FPS", value: performanceFPSLabel, systemName: "speedometer")
            SettingsInfoRow(title: "Просадки", value: performanceSlowFrameLabel, systemName: "waveform.path.ecg")
            SettingsInfoRow(title: "Худший кадр", value: performanceWorstFrameLabel, systemName: "timer")
            Button(action: resetPerformanceCounters) {
                SettingsInfoRow(title: "Метрики", value: "Сбросить", systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.plain)
        }
    }

    private var appearanceSection: some View {
        SettingsPanel(title: "Внешний вид") {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Размер ячеек", selection: $appSettings.roomCellGeometry) {
                    ForEach(RoomCellGeometry.allCases) { geometry in
                        Text(geometry.title).tag(geometry)
                    }
                }
                .pickerStyle(.segmented)

                SettingsInfoRow(
                    title: "Ячейки",
                    value: appSettings.roomCellGeometry.description,
                    systemName: "rectangle.roundedtop.fill"
                )

                SettingsSliderRow(
                    title: "Палитра",
                    valueLabel: "\(Int((appSettings.statusPaletteSaturation * 100).rounded()))%",
                    systemName: "eyedropper.halffull",
                    range: 0.70...1.65,
                    defaultValue: 1,
                    value: $appSettings.statusPaletteSaturation
                )

                Toggle(isOn: $appSettings.roomTaskLongPress) {
                    SettingsInfoRow(
                        title: "Долгий тап",
                        value: appSettings.roomTaskLongPress ? "Включен" : "Быстрый",
                        systemName: "hand.tap.fill"
                    )
                }
                .tint(OceanKeyTheme.accent)
                .onChange(of: appSettings.roomTaskLongPress) { _, _ in
                    feedback.confirm()
                }
            }
        }
    }

    private var backgroundSection: some View {
        SettingsPanel(title: "Фон приложения") {
            Picker("Заставка", selection: $appSettings.appBackgroundMode) {
                ForEach(AppBackgroundMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: appSettings.appBackgroundMode) { _, _ in
                feedback.confirm()
            }

            SettingsInfoRow(title: "Заставка", value: appSettings.appBackgroundMode.description, systemName: "grid")
            if appSettings.appBackgroundMode == .matrixRain {
                SettingsSliderRow(
                    title: "Скорость",
                    valueLabel: "\(String(format: "%.2f", appSettings.matrixSpeed))x",
                    systemName: "speedometer",
                    range: 0.08...3.0,
                    defaultValue: MatrixRainConfiguration.default.speed,
                    value: $appSettings.matrixSpeed
                )
            }
            if appSettings.appBackgroundMode == .video {
                videoBackgroundControls
            }
        }
    }

    private var videoBackgroundControls: some View {
        let videoStatus = appSettings.backgroundVideoRelativePath == nil ? "Выбрать" : "Выбрано"

        return VStack(alignment: .leading, spacing: 12) {
            PhotosPicker(
                selection: $selectedBackgroundVideoItem,
                matching: .videos,
                photoLibrary: .shared()
            ) {
                SettingsInfoRow(
                    title: "Видео",
                    value: videoStatus,
                    systemName: "film.fill"
                )
            }
            .buttonStyle(.plain)
            .onChange(of: selectedBackgroundVideoItem) { _, item in
                guard let item else { return }
                Task { await importBackgroundVideo(item) }
            }

            SettingsSliderRow(
                title: "Матовость",
                valueLabel: "\(Int((appSettings.backgroundVideoBlur * 100).rounded()))%",
                systemName: "aqi.medium",
                range: 0...1,
                defaultValue: 0.28,
                value: $appSettings.backgroundVideoBlur
            )
        }
    }

    private var workSection: some View {
        SettingsPanel(title: "Работа") {
            Toggle(isOn: $appSettings.summaryActionMenuAllowsMultiple) {
                SettingsInfoRow(
                    title: "Мульти-меню",
                    value: appSettings.summaryActionMenuAllowsMultiple ? "Несколько" : "Одно",
                    systemName: "rectangle.stack.fill"
                )
            }
            .tint(OceanKeyTheme.accent)
            .onChange(of: appSettings.summaryActionMenuAllowsMultiple) { _, _ in
                feedback.confirm()
            }
        }
    }

    private var storageSection: some View {
        SettingsPanel(title: "Локальные данные") {
            SettingsInfoRow(title: "Ячеек", value: "\(workSession.counts.total)", systemName: "rectangle.grid.1x2")
            SettingsInfoRow(title: "Готово", value: "\(workSession.counts.completed)", systemName: "checkmark.circle.fill")
            Button(action: openHistory) {
                SettingsInfoRow(title: "Хронология", value: "\(workSession.history.count)", systemName: "clock.arrow.circlepath")
            }
            .buttonStyle(.plain)
            SettingsInfoRow(title: "Хранилище", value: persistenceStatus, systemName: "externaldrive.fill")
            SettingsInfoRow(title: "iCloud", value: RuntimeDiagnostics.appleSyncStatusLabel, systemName: "icloud.slash.fill")
            if workSession.selection.workdayLocked {
                Button(action: unlockWorkdayForEditing) {
                    SettingsInfoRow(title: "Рабочий список", value: "Редактировать", systemName: "square.and.pencil")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var settingsSection: some View {
        SettingsPanel(title: "Настройки") {
            Button(action: confirmResetSettings) {
                SettingsInfoRow(title: "Сброс", value: "По умолчанию", systemName: "arrow.counterclockwise.circle.fill")
            }
            .buttonStyle(.plain)
        }
    }

    private var migrationSection: some View {
        SettingsPanel(title: "Перенос") {
            Text("Эта Swift-версия пока идёт отдельной веткой. Flutter-приложение остаётся эталоном поведения до полной готовности нативной версии.")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var persistenceStatus: String {
        if let error = workSession.lastPersistenceError {
            return "Ошибка: \(error.localizedDescription)"
        }
        return "Активно"
    }

    private var performanceFPSLabel: String {
        let currentFPS = performanceTelemetry.currentFPS == 0 ? "..." : "\(performanceTelemetry.currentFPS)"
        return "\(currentFPS) / \(performanceTelemetry.targetFPS)"
    }

    private var performanceSlowFrameLabel: String {
        "\(performanceTelemetry.recentSlowFrames) сейчас, \(performanceTelemetry.totalSlowFrames) всего"
    }

    private var performanceWorstFrameLabel: String {
        String(format: "%.1f ms", performanceTelemetry.recentWorstFrameMS)
    }

    private func unlockWorkdayForEditing() {
        feedback.confirm()
        workSession.unlockWorkdayForEditing()
        dismiss()
    }

    private func openChangelog() {
        feedback.tap()
        isChangelogPresented = true
    }

    private func openHistory() {
        feedback.tap()
        isHistoryPresented = true
    }

    private func resetPerformanceCounters() {
        feedback.confirm()
        performanceTelemetry.resetCounters()
    }

    private func confirmResetSettings() {
        feedback.tap()
        isResetConfirmationPresented = true
    }

    private func resetSettings() {
        feedback.confirm()
        appSettings.resetToDefaults()
    }

    @MainActor
    private func importBackgroundVideo(_ item: PhotosPickerItem) async {
        do {
            guard let pickedVideo = try await item.loadTransferable(type: PickedBackgroundVideo.self) else { return }
            let relativePath = try BackgroundVideoFileStore().saveVideo(from: pickedVideo.url)
            appSettings.backgroundVideoRelativePath = relativePath
            appSettings.appBackgroundMode = .video
            feedback.confirm()
        } catch {
            feedback.holdWarning()
        }
    }
}

private struct PickedBackgroundVideo: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let copyURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension)
            if FileManager.default.fileExists(atPath: copyURL.path) {
                try FileManager.default.removeItem(at: copyURL)
            }
            try FileManager.default.copyItem(at: received.file, to: copyURL)
            return PickedBackgroundVideo(url: copyURL)
        }
    }
}

#Preview {
    SettingsScreen(
        workSession: .preview(),
        appSettings: AppSettingsStore(),
        performanceTelemetry: PerformanceTelemetryStore()
    )
        .preferredColorScheme(.dark)
}
