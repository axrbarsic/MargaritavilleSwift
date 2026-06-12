import Foundation

extension WorkSessionStore {
    func updateTextNote(_ text: String, roomId: RoomCell.ID) {
        mutateRoom(roomId, history: { _, after, _ in
            (.roomTextNoteChanged, "\(after.id): текстовая заметка")
        }) { room in
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            room.textNote = trimmed.isEmpty ? nil : text
            room.textNoteUpdatedAt = trimmed.isEmpty ? nil : Date()
        }
    }

    func updateVoiceTranscript(_ text: String, roomId: RoomCell.ID) {
        mutateRoom(roomId, history: { _, after, _ in
            (.roomVoiceTranscriptChanged, "\(after.id): голосовая заметка")
        }) { room in
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            room.voiceTranscript = trimmed.isEmpty ? nil : text
            room.voiceTranscriptUpdatedAt = trimmed.isEmpty ? nil : Date()
        }
    }

    func addRoomMedia(_ attachment: MediaAttachment, roomId: RoomCell.ID) {
        mutateRoom(roomId, history: { _, after, _ in
            (.roomMediaAdded, "\(after.id): добавлено \(attachment.historyLabel)")
        }) { room in
            var attachments = room.mediaAttachments ?? []
            attachments.insert(attachment, at: 0)
            room.mediaAttachments = attachments
        }
    }

    func removeRoomMedia(_ attachment: MediaAttachment, roomId: RoomCell.ID) {
        mutateRoom(roomId, history: { _, after, _ in
            (.roomMediaAdded, "\(after.id): удалено \(attachment.historyLabel)")
        }) { room in
            var attachments = room.mediaAttachments ?? []
            attachments.removeAll { $0.id == attachment.id }
            room.mediaAttachments = attachments.isEmpty ? nil : attachments
            if attachment.kind == .audio, room.voiceTranscript == attachment.transcript {
                room.voiceTranscript = nil
                room.voiceTranscriptUpdatedAt = nil
            }
        }
    }

    func updateCartNote(_ text: String, cartId: CartSection.ID) {
        mutateCart(cartId, history: { _, after, _ in
            (.cartNoteChanged, "Тележка \(after.id): заметка")
        }) { cart in
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            cart.note = trimmed.isEmpty ? nil : text
            cart.noteUpdatedAt = trimmed.isEmpty ? nil : Date()
        }
    }

    func addCartMedia(_ attachment: MediaAttachment, cartId: CartSection.ID) {
        mutateCart(cartId, history: { _, after, _ in
            (.cartMediaAdded, "Тележка \(after.id): добавлено \(attachment.historyLabel)")
        }) { cart in
            var attachments = cart.mediaAttachments ?? []
            attachments.insert(attachment, at: 0)
            cart.mediaAttachments = attachments
        }
    }

    func removeCartMedia(_ attachment: MediaAttachment, cartId: CartSection.ID) {
        mutateCart(cartId, history: { _, after, _ in
            (.cartMediaAdded, "Тележка \(after.id): удалено \(attachment.historyLabel)")
        }) { cart in
            var attachments = cart.mediaAttachments ?? []
            attachments.removeAll { $0.id == attachment.id }
            cart.mediaAttachments = attachments.isEmpty ? nil : attachments
            if attachment.kind == .audio, cart.note == attachment.transcript {
                cart.note = nil
                cart.noteUpdatedAt = nil
            }
        }
    }
}

private extension MediaAttachment {
    var historyLabel: String {
        switch kind {
        case .photo:
            "фото"
        case .video:
            "видео"
        case .audio:
            "голос"
        }
    }
}
