import SwiftUI

struct DeepSeekLabSection: View {
    private enum GenerationState: Equatable {
        case idle
        case generating
        case ready(AIVisualPresetDraft)
        case failed(String)
    }

    @Bindable var presetStore: AIVisualPresetStore
    @Bindable var appSettings: AppSettingsStore
    @Binding var modelTier: DeepSeekModelTier
    @Environment(\.interactionFeedback) private var feedback
    @State private var prompt = "Матрица из красивого Swift-кода, зелёное свечение, дорогой терминальный стиль."
    @State private var kind: AIVisualPresetKind = .matrixCodeRain
    @State private var apiKeyInput = ""
    @State private var hasAPIKey = false
    @State private var state = GenerationState.idle
    @State private var backupDocument: OceanKeyPresetBackupDocument?
    @State private var backupFilename = OceanKeyPresetBackupDocument.filename()
    @State private var isBackupExporterPresented = false
    @State private var backupMessage: String?
    @State private var shouldSuggestBackup = false

    private let client = DeepSeekClient()
    private let secretStore = KeychainSecretStore()
    private let apiKeyAccount = "deepseek-api-key"

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            apiKeyPanel
            generatorPanel
            savedPresetsPanel
        }
        .onAppear {
            refreshAPIKeyState()
            presetStore.load()
        }
        .fileExporter(
            isPresented: $isBackupExporterPresented,
            document: backupDocument,
            contentType: .oceanKeyPresetBackup,
            defaultFilename: backupFilename,
            onCompletion: handleBackupExportCompletion
        )
    }

    private var apiKeyPanel: some View {
        SettingsPanel(
            title: "DeepSeek Lab",
            subtitle: "Ключ хранится в iOS Keychain. Пресеты сохраняются отдельным SwiftData store."
        ) {
            SettingsInfoRow(
                title: "API ключ",
                value: hasAPIKey ? "Сохранён" : "Нет",
                systemName: hasAPIKey ? "key.fill" : "key.slash.fill",
                subtitle: "В код приложения ключ не зашивается."
            )

            SettingsInfoRow(
                title: presetStore.storageMode.statusTitle,
                value: presetStore.storageMode.isAppleSynced ? "iCloud" : "Локально",
                systemName: presetStore.storageMode.isAppleSynced ? "icloud.fill" : "icloud.slash.fill",
                subtitle: presetStore.storageMode.statusDetails
            )

            SecureField("Вставь DeepSeek API key", text: $apiKeyInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 54)
                .background(OceanKeyTheme.surface.opacity(0.84))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(OceanKeyTheme.accent.opacity(0.18), lineWidth: 1)
                }

            HStack(spacing: 10) {
                Button(action: saveKey) {
                    DeepSeekActionButtonLabel(title: "Сохранить", systemName: "checkmark.seal.fill")
                }
                .buttonStyle(.plain)
                .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button(action: deleteKey) {
                    DeepSeekActionButtonLabel(title: "Удалить", systemName: "trash.fill", destructive: true)
                }
                .buttonStyle(.plain)
                .disabled(!hasAPIKey)
            }
        }
    }

    private var generatorPanel: some View {
        SettingsPanel(
            title: "Генератор пресетов",
            subtitle: "AI придумывает параметры, а OceanKey рендерит их локально через Swift/SpriteKit."
        ) {
            Picker("Тип", selection: $kind) {
                ForEach(AIVisualPresetKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            Picker("Модель", selection: $modelTier) {
                ForEach(DeepSeekModelTier.allCases) { tier in
                    Text(tier.title).tag(tier)
                }
            }
            .pickerStyle(.segmented)

            TextEditor(text: $prompt)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 104)
                .padding(10)
                .background(OceanKeyTheme.surface.opacity(0.84))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(OceanKeyTheme.accent.opacity(0.18), lineWidth: 1)
                }

            Button(action: generate) {
                DeepSeekActionButtonLabel(
                    title: state == .generating ? "Генерирую..." : "Сгенерировать",
                    systemName: "sparkles"
                )
            }
            .buttonStyle(.plain)
            .disabled(state == .generating || !hasAPIKey)

            generatorStateView
        }
    }

    @ViewBuilder
    private var generatorStateView: some View {
        switch state {
        case .idle:
            EmptyView()
        case .generating:
            SettingsInfoRow(
                title: "DeepSeek думает",
                value: modelTier.title,
                systemName: "brain.head.profile",
                subtitle: "Запрашиваю JSON-пресет, не видео и не тяжёлый runtime."
            )
        case .ready(let draft):
            VStack(alignment: .leading, spacing: 10) {
                DeepSeekPresetCard(preset: draft)
                Button(action: saveCurrentDraft) {
                    DeepSeekActionButtonLabel(
                        title: presetStore.storageMode.isAppleSynced ? "Сохранить в Apple" : "Сохранить локально",
                        systemName: presetStore.storageMode.isAppleSynced ? "icloud.and.arrow.up.fill" : "externaldrive.fill"
                    )
                }
                .buttonStyle(.plain)
                if !presetStore.storageMode.isAppleSynced {
                    Text("CloudKit сейчас недоступен: этот вариант сохранится только локально до исправления Apple provisioning.")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.yellow.opacity(0.92))
                }
            }
        case .failed(let message):
            SettingsInfoRow(
                title: "Ошибка",
                value: "Проверить",
                systemName: "exclamationmark.triangle.fill",
                subtitle: message
            )
        }
    }

    private var savedPresetsPanel: some View {
        SettingsPanel(
            title: "Сохранённые AI-пресеты",
            subtitle: "Эти записи лёгкие: JSON-параметры, а не видеофайлы."
        ) {
            backupActions

            if presetStore.presets.isEmpty {
                SettingsInfoRow(
                    title: "Пока пусто",
                    value: "0",
                    systemName: "tray.fill",
                    subtitle: "Сгенерируй вариант и нажми сохранить."
                )
            } else {
                ForEach(presetStore.presets) { preset in
                    SavedDeepSeekPresetRow(
                        preset: preset,
                        onDelete: {
                            feedback.holdWarning()
                            presetStore.delete(preset)
                        }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var backupActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: exportBackup) {
                DeepSeekActionButtonLabel(
                    title: "Сохранить backup в Файлы",
                    systemName: "square.and.arrow.up.fill"
                )
            }
            .buttonStyle(.plain)

            if shouldSuggestBackup {
                Text("Пресет сохранён. Сейчас удобно отправить backup в iCloud Drive, чтобы не потерять конфигурацию.")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText)
            }

            if let backupMessage {
                Text(backupMessage)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText)
            }
        }
    }

    private func saveKey() {
        feedback.confirm()
        do {
            let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            try secretStore.saveSecret(trimmed, account: apiKeyAccount)
            apiKeyInput = ""
            hasAPIKey = true
            state = .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func deleteKey() {
        feedback.holdWarning()
        do {
            try secretStore.deleteSecret(account: apiKeyAccount)
            hasAPIKey = false
            state = .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func generate() {
        feedback.confirm()
        Task {
            state = .generating
            do {
                guard let apiKey = try secretStore.readSecret(account: apiKeyAccount) else {
                    state = .failed("Сначала вставь DeepSeek API ключ.")
                    return
                }
                let draft = try await client.generatePreset(
                    apiKey: apiKey,
                    modelTier: modelTier,
                    kind: kind,
                    prompt: prompt
                )
                state = .ready(draft)
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    private func saveCurrentDraft() {
        feedback.confirm()
        guard case .ready(let draft) = state else { return }
        presetStore.save(draft: draft, modelTier: modelTier, prompt: prompt)
        state = .idle
        shouldSuggestBackup = true
        backupMessage = "Готов backup: пресеты и текущая конфигурация заставки."
    }

    private func exportBackup() {
        feedback.confirm()
        presetStore.load()
        let exportedAt = Date()
        let payload = OceanKeyPresetBackupPayload.make(
            presets: presetStore.presets,
            appSettings: appSettings,
            exportedAt: exportedAt
        )
        backupDocument = OceanKeyPresetBackupDocument(payload: payload)
        backupFilename = OceanKeyPresetBackupDocument.filename(exportedAt: exportedAt)
        isBackupExporterPresented = true
        shouldSuggestBackup = false
    }

    private func handleBackupExportCompletion(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            backupMessage = "Backup сохранён: \(url.lastPathComponent)"
            feedback.confirm()
        case .failure(let error):
            backupMessage = "Backup не сохранён: \(error.localizedDescription)"
            feedback.holdWarning()
        }
    }

    private func refreshAPIKeyState() {
        do {
            hasAPIKey = try secretStore.readSecret(account: apiKeyAccount) != nil
        } catch {
            hasAPIKey = false
        }
    }
}
