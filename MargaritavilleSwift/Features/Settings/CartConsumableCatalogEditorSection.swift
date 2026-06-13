import SwiftUI

struct CartConsumableCatalogEditorSection: View {
    @Bindable var appSettings: AppSettingsStore
    @Environment(\.interactionFeedback) private var feedback
    @State private var newTitle = ""
    @State private var message = "Этот список используется в меню уборщицы для быстрого запроса на тележку."

    var body: some View {
        SettingsPanel(
            title: "Расходники тележки",
            subtitle: "Добавляй, удаляй и переименовывай позиции для меню уборщицы."
        ) {
            inputRow
            Text(message)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)

            ForEach(appSettings.cartConsumableCatalog) { item in
                consumableRow(item)
            }
        }
    }

    private var inputRow: some View {
        HStack(spacing: 10) {
            TextField("Название", text: $newTitle)
                .textInputAutocapitalization(.sentences)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(.black.opacity(0.24))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .onSubmit(addConsumable)

            Button(action: addConsumable) {
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

    private func consumableRow(_ item: CartConsumableCatalogItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 18, weight: .black))
                .frame(width: 38, height: 38)
                .foregroundStyle(OceanKeyTheme.accent)
                .background(OceanKeyTheme.accent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            CartConsumableCatalogNameField(item: item) { title in
                appSettings.renameCartConsumableCatalogItem(id: item.id, title: title)
                message = "\(title) сохранено."
            }

            Button {
                removeConsumable(item)
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
                .stroke(OceanKeyTheme.accent.opacity(0.18), lineWidth: 1)
        }
    }

    private func addConsumable() {
        if let item = appSettings.addCartConsumableCatalogItem(named: newTitle) {
            feedback.confirm()
            message = "\(item.title) добавлено."
            newTitle = ""
        } else {
            feedback.holdWarning()
            message = "Напиши название перед добавлением."
        }
    }

    private func removeConsumable(_ item: CartConsumableCatalogItem) {
        feedback.deselect()
        appSettings.removeCartConsumableCatalogItem(id: item.id)
        message = "\(item.title) удалено из списка."
    }
}

private struct CartConsumableCatalogNameField: View {
    let item: CartConsumableCatalogItem
    let onCommit: (String) -> Void
    @State private var draftTitle: String

    init(item: CartConsumableCatalogItem, onCommit: @escaping (String) -> Void) {
        self.item = item
        self.onCommit = onCommit
        _draftTitle = State(initialValue: item.title)
    }

    var body: some View {
        TextField("Название", text: $draftTitle)
            .textInputAutocapitalization(.sentences)
            .font(.system(size: 17, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(.black.opacity(0.20))
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .onSubmit(commit)
            .onChange(of: draftTitle) { _, value in
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                onCommit(trimmed)
            }
    }

    private func commit() {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            draftTitle = item.title
        } else {
            onCommit(trimmed)
        }
    }
}
