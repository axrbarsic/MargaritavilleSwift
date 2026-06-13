import SwiftUI

struct HousekeeperCatalogEditorSection: View {
    @Bindable var appSettings: AppSettingsStore
    @Bindable var workSession: WorkSessionStore
    @Environment(\.interactionFeedback) private var feedback
    @State private var newName = ""
    @State private var message = "Имена идут из свежих листов; список можно менять под смену."

    var body: some View {
        SettingsPanel(
            title: "Уборщицы",
            subtitle: "Имена, цвета и назначения тележек для первого экрана Margaritaville."
        ) {
            inputRow
            Text(message)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
            ForEach(appSettings.housekeepers) { housekeeper in
                housekeeperRow(housekeeper)
            }
        }
    }

    private var inputRow: some View {
        HStack(spacing: 10) {
            TextField("Имя", text: $newName)
                .textInputAutocapitalization(.words)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(.black.opacity(0.24))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button(action: addHousekeeper) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .black))
                    .frame(width: 48, height: 48)
                    .foregroundStyle(OceanKeyTheme.roomForeground)
                    .background(OceanKeyTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func housekeeperRow(_ housekeeper: Housekeeper) -> some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(HousekeeperPalette.allCases) { palette in
                    Button {
                        feedback.tap()
                        appSettings.setHousekeeperPalette(id: housekeeper.id, palette: palette)
                    } label: {
                        Text(palette.rawValue.capitalized)
                    }
                }
            } label: {
                Circle()
                    .fill(housekeeper.palette.color)
                    .frame(width: 38, height: 38)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.65), lineWidth: 1.2)
                    }
            }
            .buttonStyle(.plain)

            HousekeeperNameField(
                housekeeper: housekeeper,
                onCommit: { name in
                    appSettings.renameHousekeeper(id: housekeeper.id, displayName: name)
                    message = "\(name) сохранена."
                }
            )

            Button {
                removeHousekeeper(housekeeper)
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 15, weight: .black))
                    .frame(width: 42, height: 42)
                    .foregroundStyle(.white.opacity(0.82))
                    .background(Color.red.opacity(0.24))
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(OceanKeyTheme.surface.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(housekeeper.palette.color.opacity(0.34), lineWidth: 1)
        }
    }

    private func addHousekeeper() {
        if let housekeeper = appSettings.addHousekeeper(named: newName) {
            feedback.confirm()
            message = "\(housekeeper.displayName) добавлена."
            newName = ""
        } else {
            feedback.holdWarning()
            message = "Напиши имя перед добавлением."
        }
    }

    private func removeHousekeeper(_ housekeeper: Housekeeper) {
        feedback.deselect()
        appSettings.removeHousekeeper(id: housekeeper.id)
        workSession.removeHousekeeperAssignments(housekeeperID: housekeeper.id)
        message = "\(housekeeper.displayName) удалена из списка."
    }
}

private struct HousekeeperNameField: View {
    let housekeeper: Housekeeper
    let onCommit: (String) -> Void
    @State private var draftName: String

    init(housekeeper: Housekeeper, onCommit: @escaping (String) -> Void) {
        self.housekeeper = housekeeper
        self.onCommit = onCommit
        _draftName = State(initialValue: housekeeper.displayName)
    }

    var body: some View {
        TextField("Имя", text: $draftName)
            .textInputAutocapitalization(.words)
            .font(.system(size: 17, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(.black.opacity(0.20))
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .onSubmit(commit)
            .onChange(of: draftName) { _, value in
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                onCommit(trimmed)
            }
    }

    private func commit() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            draftName = housekeeper.displayName
        } else {
            onCommit(trimmed)
        }
    }
}
