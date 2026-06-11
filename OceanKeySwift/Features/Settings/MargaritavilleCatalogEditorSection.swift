import SwiftUI

struct MargaritavilleCatalogEditorSection: View {
    @Bindable var workSession: WorkSessionStore
    @Environment(\.interactionFeedback) private var feedback
    @State private var roomInput = ""
    @State private var message = "Добавь номер, и корпус/этаж определятся автоматически."

    var body: some View {
        SettingsPanel(
            title: "Каталог Margaritaville",
            subtitle: "Добавление и удаление номеров хранится в отдельной базе этого отеля."
        ) {
            inputRow
            Text(message)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
            ForEach(workSession.effectiveCatalog) { territory in
                territoryCard(territory)
            }
        }
    }

    private var inputRow: some View {
        HStack(spacing: 10) {
            TextField("Номер", text: $roomInput)
                .keyboardType(.numbersAndPunctuation)
                .textInputAutocapitalization(.characters)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(.black.opacity(0.24))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button(action: addRoom) {
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

    private func territoryCard(_ territory: Territory) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(territory.label)
                Spacer()
                Text("\(territory.rooms.count)")
                    .monospacedDigit()
            }
            .font(.system(size: 17, weight: .black, design: .rounded))
            .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 54), spacing: 7)], spacing: 7) {
                ForEach(territory.rooms, id: \.self) { room in
                    roomChip(room)
                }
            }
        }
        .padding(12)
        .background(OceanKeyTheme.surface.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(OceanKeyTheme.accent.opacity(0.16), lineWidth: 1)
        }
    }

    private func roomChip(_ room: RoomID) -> some View {
        Button {
            removeRoom(room)
        } label: {
            HStack(spacing: 4) {
                Text(room)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .black))
            }
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(.black.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func addRoom() {
        let input = roomInput
        switch workSession.addCatalogRoom(input) {
        case .changed:
            feedback.confirm()
            message = "\(RoomCatalog.normalizeRoomID(input) ?? input) добавлен."
            roomInput = ""
        case .duplicate:
            feedback.holdWarning()
            message = "Этот номер уже есть в каталоге."
        case .invalidRoom:
            feedback.holdWarning()
            message = "Не могу определить корпус/этаж для этого номера."
        case .blockedActiveRoom:
            feedback.holdWarning()
            message = "Этот номер сейчас используется в смене."
        case .unsupportedHotel:
            feedback.holdWarning()
            message = "Редактор доступен только для Margaritaville."
        }
    }

    private func removeRoom(_ room: RoomID) {
        switch workSession.removeCatalogRoom(room) {
        case .changed:
            feedback.confirm()
            message = "\(room) удалён из каталога."
        case .blockedActiveRoom:
            feedback.holdWarning()
            message = "\(room) сейчас в активной смене, удалить нельзя."
        case .duplicate, .invalidRoom:
            feedback.holdWarning()
            message = "Номер \(room) не найден в каталоге."
        case .unsupportedHotel:
            feedback.holdWarning()
            message = "Редактор доступен только для Margaritaville."
        }
    }
}
