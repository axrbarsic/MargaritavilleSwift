import SwiftUI

struct SettingsScreen: View {
    @Bindable var workSession: WorkSessionStore
    @Bindable var appSettings: AppSettingsStore
    @Bindable var performanceTelemetry: PerformanceTelemetryStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.interactionFeedback) private var feedback
    @State private var isChangelogPresented = false
    @State private var isHistoryPresented = false

    var body: some View {
        ZStack {
            SpriteKitEffectView(.matrixRain)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    appearanceSection
                    developerSection
                    storageSection
                    migrationSection
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

    private var developerSection: some View {
        SettingsPanel(title: "Разработчик") {
            SettingsInfoRow(title: "Версия", value: AppBuildInfo.versionLabel, systemName: "number")
            Button(action: openChangelog) {
                SettingsInfoRow(title: "Что изменилось", value: "Открыть", systemName: "list.bullet.clipboard.fill")
            }
            .buttonStyle(.plain)
            SettingsInfoRow(title: "Движок", value: "SpriteKit + SwiftUI", systemName: "sparkles")
            SettingsInfoRow(title: "Цель", value: "Физический iPhone", systemName: "iphone")
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

    private var storageSection: some View {
        SettingsPanel(title: "Локальные данные") {
            SettingsInfoRow(title: "Ячеек", value: "\(workSession.counts.total)", systemName: "rectangle.grid.1x2")
            SettingsInfoRow(title: "Готово", value: "\(workSession.counts.completed)", systemName: "checkmark.circle.fill")
            Button(action: openHistory) {
                SettingsInfoRow(title: "Хронология", value: "\(workSession.history.count)", systemName: "clock.arrow.circlepath")
            }
            .buttonStyle(.plain)
            SettingsInfoRow(title: "Хранилище", value: persistenceStatus, systemName: "externaldrive.fill")
            if workSession.selection.workdayLocked {
                Button(action: unlockWorkdayForEditing) {
                    SettingsInfoRow(title: "Рабочий список", value: "Редактировать", systemName: "square.and.pencil")
                }
                .buttonStyle(.plain)
            }
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
}

private struct SettingsPanel<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                content
            }
            .padding(14)
            .background(OceanKeyTheme.surface.opacity(0.84))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(OceanKeyTheme.accent.opacity(0.22), lineWidth: 1)
            }
        }
    }
}

private struct SettingsInfoRow: View {
    let title: String
    let value: String
    let systemName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .black))
                .frame(width: 34, height: 34)
                .foregroundStyle(OceanKeyTheme.accent)
                .background(OceanKeyTheme.accent.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(title)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Spacer(minLength: 12)

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(minHeight: 48)
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
