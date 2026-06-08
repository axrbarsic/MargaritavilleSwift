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
        case .sync:
            syncSection
            storageSection
        case .tools:
            toolsSection
        case .developer:
            experimentalSection
            developerSection
            migrationSection
        }
    }

    private var experimentalSection: some View {
        SettingsPanel(
            title: "Экспериментальное",
            subtitle: "Только активные режимы, которые можно реально оценить на основном экране."
        ) {
            Toggle(isOn: $appSettings.developerCellPhysicsEnabled) {
                SettingsInfoRow(
                    title: "Живые ячейки",
                    value: appSettings.developerCellPhysicsEnabled ? "Вкл" : "Выкл",
                    systemName: "waveform.path",
                    subtitle: "Пружинящий отклик ячеек на изменения статуса, задач и VIP."
                )
            }
            .tint(OceanKeyTheme.accent)
            .onChange(of: appSettings.developerCellPhysicsEnabled) { _, _ in
                feedback.confirm()
            }

            if appSettings.developerCellPhysicsEnabled {
                SettingsSliderRow(
                    title: "Сила пружины",
                    valueLabel: "\(Int((appSettings.developerCellSpringIntensity * 100).rounded()))%",
                    systemName: "arrow.up.and.down.and.arrow.left.and.right",
                    range: 0...1,
                    defaultValue: 0.72,
                    value: $appSettings.developerCellSpringIntensity
                )
                SettingsSliderRow(
                    title: "Скорость пружины",
                    valueLabel: "\(String(format: "%.2f", appSettings.developerCellSpringSpeed))x",
                    systemName: "speedometer",
                    range: 0.2...1.6,
                    defaultValue: 0.82,
                    value: $appSettings.developerCellSpringSpeed
                )
            }

            Toggle(isOn: $appSettings.developerCellVolumeEnabled) {
                SettingsInfoRow(
                    title: "Объёмные ячейки",
                    value: appSettings.developerCellVolumeEnabled ? "Вкл" : "Выкл",
                    systemName: "view.in.ar",
                    subtitle: "Глянцевый выпуклый вид ячеек в стиле драже из Flutter-версии."
                )
            }
            .tint(OceanKeyTheme.accent)
            .onChange(of: appSettings.developerCellVolumeEnabled) { _, _ in
                feedback.confirm()
            }

            if appSettings.developerCellVolumeEnabled {
                SettingsSliderRow(
                    title: "Сила объёма",
                    valueLabel: "\(Int((appSettings.developerCellVolumeIntensity * 100).rounded()))%",
                    systemName: "circle.grid.cross",
                    range: 0...1,
                    defaultValue: 0.78,
                    value: $appSettings.developerCellVolumeIntensity
                )
            }

            SettingsSliderRow(
                title: "VIP-зебра",
                valueLabel: "\(Int((appSettings.developerVIPZebraIntensity * 100).rounded()))%",
                systemName: "line.3.horizontal.decrease.circle.fill",
                range: 0...1,
                defaultValue: 0.86,
                value: $appSettings.developerVIPZebraIntensity
            )
            SettingsSliderRow(
                title: "Скорость VIP",
                valueLabel: "\(String(format: "%.2f", appSettings.developerVIPZebraSpeed))x",
                systemName: "speedometer",
                range: 0.2...1.8,
                defaultValue: 0.78,
                value: $appSettings.developerVIPZebraSpeed
            )
        }
    }

    private var developerSection: some View {
        SettingsPanel(
            title: "Разработчик",
            subtitle: "Диагностика, версия приложения и технические признаки текущей сборки."
        ) {
            SettingsInfoRow(
                title: "Версия",
                value: AppBuildInfo.versionLabel,
                systemName: "number",
                subtitle: "Нажми ниже, чтобы открыть краткий список изменений."
            )
            Button(action: openChangelog) {
                SettingsInfoRow(
                    title: "Что изменилось",
                    value: "Открыть",
                    systemName: "list.bullet.clipboard.fill",
                    subtitle: "Короткая выжимка по последним билдам."
                )
            }
            .buttonStyle(.plain)
            SettingsInfoRow(title: "Движок", value: "SpriteKit + SwiftUI", systemName: "sparkles")
            SettingsInfoRow(title: "Цель", value: "Физический iPhone", systemName: "iphone")
            SettingsInfoRow(title: "ProMotion", value: RuntimeDiagnostics.currentProMotionStatusLabel(), systemName: "display")
            SettingsInfoRow(title: "FPS", value: performanceFPSLabel, systemName: "speedometer")
            SettingsInfoRow(title: "Просадки", value: performanceSlowFrameLabel, systemName: "waveform.path.ecg")
            SettingsInfoRow(title: "Худший кадр", value: performanceWorstFrameLabel, systemName: "timer")
            Button(action: resetPerformanceCounters) {
                SettingsInfoRow(
                    title: "Метрики",
                    value: "Сбросить",
                    systemName: "arrow.counterclockwise",
                    subtitle: "Обнулить счётчики FPS и медленных кадров."
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var appearanceSection: some View {
        SettingsPanel(
            title: "Внешний вид",
            subtitle: "Размер ячеек, палитра статусов и жесты задач на основном экране."
        ) {
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
                    systemName: "rectangle.roundedtop.fill",
                    subtitle: "Можно оставить просторный размер или вернуться ближе к компактному виду."
                )

                Toggle(isOn: $appSettings.vividStatusPaletteEnabled) {
                    SettingsInfoRow(
                        title: "Сочная палитра",
                        value: appSettings.vividStatusPaletteEnabled ? "Скриншот" : "Обычная",
                        systemName: "paintpalette.fill",
                        subtitle: "Второй режим фиксирует яркие цвета ячеек как на твоём скриншоте."
                    )
                }
                .tint(OceanKeyTheme.accent)
                .onChange(of: appSettings.vividStatusPaletteEnabled) { _, _ in
                    feedback.confirm()
                }

                Toggle(isOn: $appSettings.roomTaskLongPress) {
                    SettingsInfoRow(
                        title: "Долгий тап",
                        value: appSettings.roomTaskLongPress ? "Включен" : "Быстрый",
                        systemName: "hand.tap.fill",
                        subtitle: "Защищает S, L, B от случайных касаний во время скролла."
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
        SettingsPanel(
            title: "Фон приложения",
            subtitle: "Matrix Rain или локальное видео как живая заставка основного экрана."
        ) {
            Picker("Заставка", selection: $appSettings.appBackgroundMode) {
                ForEach(AppBackgroundMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: appSettings.appBackgroundMode) { _, _ in
                feedback.confirm()
            }

            SettingsInfoRow(
                title: "Заставка",
                value: appSettings.appBackgroundMode.description,
                systemName: "grid",
                subtitle: "Видео хранится только локально на устройстве."
            )
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
                BackgroundVideoPickerLabel(videoStatus: videoStatus)
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
            SettingsSliderRow(
                title: "Яркость",
                valueLabel: "\(Int((appSettings.backgroundVideoBrightness * 100).rounded()))%",
                systemName: "sun.max.fill",
                range: -0.45...0.45,
                defaultValue: 0,
                value: $appSettings.backgroundVideoBrightness
            )
            SettingsSliderRow(
                title: "Зелёный оттенок",
                valueLabel: "\(Int((appSettings.backgroundVideoGreenTint * 100).rounded()))%",
                systemName: "leaf.fill",
                range: 0...1,
                defaultValue: 0.34,
                value: $appSettings.backgroundVideoGreenTint
            )
        }
    }

    private var workSection: some View {
        SettingsPanel(
            title: "Работа",
            subtitle: "Поведение раздвижного меню ячейки и рабочие жесты на основном экране."
        ) {
            Toggle(isOn: $appSettings.summaryActionMenuAllowsMultiple) {
                SettingsInfoRow(
                    title: "Мульти-меню",
                    value: appSettings.summaryActionMenuAllowsMultiple ? "Несколько" : "Одно",
                    systemName: "rectangle.stack.fill",
                    subtitle: "По умолчанию открыто только одно меню ячейки; этот режим разрешает несколько."
                )
            }
            .tint(OceanKeyTheme.accent)
            .onChange(of: appSettings.summaryActionMenuAllowsMultiple) { _, _ in
                feedback.confirm()
            }
        }
    }

    private var syncSection: some View {
        SettingsPanel(
            title: "Синхронизация",
            subtitle: "Swift-версия готовится под Apple-first хранение и будущую iCloud-синхронизацию."
        ) {
            SettingsInfoRow(
                title: "iCloud",
                value: RuntimeDiagnostics.appleSyncStatusLabel,
                systemName: "icloud.slash.fill",
                subtitle: "Firebase больше не является ориентиром для нативной iOS-ветки."
            )
            SettingsInfoRow(
                title: "Локальный режим",
                value: persistenceStatus,
                systemName: "externaldrive.fill",
                subtitle: "Данные сначала сохраняются на устройстве, без блокировки интерфейса."
            )
            Button(action: openHistory) {
                SettingsInfoRow(
                    title: "Хронология",
                    value: "\(workSession.history.count)",
                    systemName: "clock.arrow.circlepath",
                    subtitle: "События работы с ячейками и тележками."
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var storageSection: some View {
        SettingsPanel(
            title: "Текущая смена",
            subtitle: "Быстрый технический срез активного рабочего списка."
        ) {
            SettingsInfoRow(title: "Ячеек", value: "\(workSession.counts.total)", systemName: "rectangle.grid.1x2")
            SettingsInfoRow(title: "Готово", value: "\(workSession.counts.completed)", systemName: "checkmark.circle.fill")
            if workSession.selection.workdayLocked {
                Button(action: unlockWorkdayForEditing) {
                    SettingsInfoRow(
                        title: "Рабочий список",
                        value: "Редактировать",
                        systemName: "square.and.pencil",
                        subtitle: "Разблокировать первый экран для правки тележек и номеров."
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var toolsSection: some View {
        SettingsPanel(
            title: "Инструменты",
            subtitle: "Встроенные помощники Swift-версии. AI-перевод и Gemini пока не показываем."
        ) {
            SettingsInfoRow(
                title: "Диктофон",
                value: "Apple Speech",
                systemName: "mic.fill",
                subtitle: "Нативная запись и расшифровка заметок без Gemini как основного пути."
            )
            SettingsInfoRow(
                title: "Медиа",
                value: "Локально",
                systemName: "camera.fill",
                subtitle: "Фото и видео остаются на устройстве, без облачной синхронизации."
            )
            SettingsInfoRow(
                title: "Видео-фон",
                value: appSettings.backgroundVideoRelativePath == nil ? "Не выбран" : "Готов",
                systemName: "film.stack.fill",
                subtitle: "Тот же локальный файл используется как фон приложения."
            )
        }
    }

    private var settingsSection: some View {
        SettingsPanel(
            title: "Сброс",
            subtitle: "Вернуть визуальные и рабочие параметры к значениям по умолчанию."
        ) {
            Button(action: confirmResetSettings) {
                SettingsInfoRow(
                    title: "Сброс настроек",
                    value: "По умолчанию",
                    systemName: "arrow.counterclockwise.circle.fill",
                    subtitle: "Не удаляет рабочую смену, но сбрасывает внешний вид и режимы."
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var migrationSection: some View {
        SettingsPanel(
            title: "Перенос",
            subtitle: "Служебная заметка по текущей нативной iOS-ветке."
        ) {
            Text("Эта Swift-версия пока идёт отдельной веткой. Flutter-приложение остаётся эталоном поведения до полной готовности нативной версии.")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .background(OceanKeyTheme.surface.opacity(0.84))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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

private struct BackgroundVideoPickerLabel: View {
    let videoStatus: String

    var body: some View {
        SettingsInfoRow(
            title: "Видео",
            value: videoStatus,
            systemName: "film.fill"
        )
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
