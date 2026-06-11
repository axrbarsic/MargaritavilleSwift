import SwiftUI

struct RoomDetailsScreen: View {
    let route: RoomDetailsRoute
    @Bindable var workSession: WorkSessionStore

    @Environment(\.dismiss) private var dismiss
    @State private var draftText = ""
    @State private var draftVoiceTranscript = ""
    @State private var captureKind: MediaKind?
    @State private var selectedMedia: MediaAttachment?
    @State private var mediaPreviewPlaybackEnabled = true
    @State private var mediaError: String?

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 18) {
                header

                VStack(alignment: .leading, spacing: 14) {
                    Text(route.mode.title)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    if let updatedLabel {
                        RoomDetailsTimestamp(label: "Обновлено: \(updatedLabel)")
                    }

                    if route.mode == .voice {
                        multimodalNoteSection
                    } else if route.mode == .media {
                        mediaSection
                    } else {
                        textEditor(text: $draftText, placeholder: "Текстовая заметка")
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(OceanKeyTheme.surface.opacity(0.84))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(OceanKeyTheme.accent.opacity(0.22), lineWidth: 1)
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
        }
        .onAppear(perform: loadDraft)
        .onChange(of: draftText) { _, newValue in
            guard route.mode == .text else { return }
            workSession.updateTextNote(newValue, roomId: route.roomID)
        }
        .onChange(of: draftVoiceTranscript) { _, newValue in
            guard route.mode == .voice else { return }
            workSession.updateVoiceTranscript(newValue, roomId: route.roomID)
        }
        .fullScreenCover(item: $captureKind) { kind in
            CameraCaptureView(
                kind: kind,
                onCapture: saveCapturedMedia,
                onCancel: { captureKind = nil }
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $selectedMedia, onDismiss: {
            mediaPreviewPlaybackEnabled = true
        }) { attachment in
            MediaViewerScreen(attachments: visualMediaAttachments, initialAttachment: attachment)
        }
    }

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .black))
                    .frame(width: 48, height: 48)
                    .foregroundStyle(OceanKeyTheme.secondaryText)
                    .background(OceanKeyTheme.surface.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Text(route.roomID)
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            Spacer()
        }
    }

    private var voicePlaceholder: some View {
        VStack(spacing: 14) {
            VoiceTranscriptionPanel(
                title: "Новая голосовая заметка",
                transcript: $draftVoiceTranscript,
                onCompletion: saveVoiceResult
            )

            if voiceAttachments.isEmpty {
                Text("Голосовые заметки появятся здесь пузырями после записи.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText.opacity(0.70))
            } else {
                VStack(spacing: 10) {
                    ForEach(voiceAttachments) { attachment in
                        VoiceNoteBubble(
                            attachment: attachment,
                            onDelete: { deleteMediaAttachment(attachment) }
                        )
                    }
                }
            }
        }
    }

    private var multimodalNoteSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            voicePlaceholder

            Divider()
                .overlay(OceanKeyTheme.accent.opacity(0.18))

            mediaSection
        }
    }

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                mediaAction(systemName: "camera.fill", title: "Фото", kind: .photo)
                mediaAction(systemName: "video.fill", title: "Видео", kind: .video)
            }

            if let mediaError {
                Text(mediaError)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.pending)
            }

            if visualMediaAttachments.isEmpty {
                Text("Фото и видео сохраняются локально и не синхронизируются.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText)
            } else {
                MediaAttachmentGrid(
                    attachments: visualMediaAttachments,
                    previewsEnabled: mediaPreviewPlaybackEnabled && selectedMedia == nil,
                    onOpen: openMediaAttachment,
                    onDelete: deleteMediaAttachment
                )
            }
        }
    }

    private func mediaAction(systemName: String, title: String, kind: MediaKind) -> some View {
        Button(action: { captureKind = kind }) {
            VStack(spacing: 8) {
                Image(systemName: systemName)
                    .font(.system(size: 26, weight: .black))
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 86)
            .foregroundStyle(OceanKeyTheme.secondaryText)
            .background(OceanKeyTheme.accent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(OceanKeyTheme.accent.opacity(0.20), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func textEditor(text: Binding<String>, placeholder: String) -> some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: text)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
                .padding(10)
                .frame(minHeight: 220)
                .background(.black.opacity(0.24))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(OceanKeyTheme.accent.opacity(0.18), lineWidth: 1)
                }

            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText.opacity(0.55))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .allowsHitTesting(false)
            }
        }
    }

    private func loadDraft() {
        let room = workSession.room(id: route.roomID)
        draftText = room?.textNote ?? ""
        draftVoiceTranscript = room?.voiceTranscript ?? ""
    }

    private var allMediaAttachments: [MediaAttachment] {
        workSession.room(id: route.roomID)?.mediaAttachments ?? []
    }

    private var visualMediaAttachments: [MediaAttachment] {
        allMediaAttachments.filter { $0.kind == .photo || $0.kind == .video }
    }

    private var voiceAttachments: [MediaAttachment] {
        allMediaAttachments.filter { $0.kind == .audio }
    }

    private func saveCapturedMedia(_ capturedMedia: CapturedMedia) {
        do {
            let attachment = try LocalMediaFileStore().save(capturedMedia: capturedMedia)
            workSession.addRoomMedia(attachment, roomId: route.roomID)
            mediaError = nil
        } catch {
            mediaError = error.localizedDescription
        }
        captureKind = nil
    }

    private func saveVoiceResult(_ result: VoiceTranscriptionResult) {
        do {
            let attachment = try LocalMediaFileStore().saveVoiceAudio(
                from: result.audioURL,
                transcript: result.transcript
            )
            workSession.addRoomMedia(attachment, roomId: route.roomID)
            mediaError = nil
        } catch {
            mediaError = error.localizedDescription
        }
        try? FileManager.default.removeItem(at: result.audioURL)
    }

    private func deleteMediaAttachment(_ attachment: MediaAttachment) {
        if selectedMedia?.id == attachment.id {
            selectedMedia = nil
        }
        LocalMediaFileStore().delete(attachment)
        workSession.removeRoomMedia(attachment, roomId: route.roomID)
    }

    private func openMediaAttachment(_ attachment: MediaAttachment) {
        mediaPreviewPlaybackEnabled = false
        selectedMedia = attachment
    }

    private var updatedLabel: String? {
        let room = workSession.room(id: route.roomID)
        let date: Date? = switch route.mode {
        case .text:
            room?.textNoteUpdatedAt
        case .voice:
            room?.mediaAttachments?.first(where: { $0.kind == .audio })?.createdAt ?? room?.voiceTranscriptUpdatedAt
        case .media:
            room?.mediaAttachments?.first(where: { $0.kind == .photo || $0.kind == .video })?.createdAt
        }
        guard let date else { return nil }
        return date.formatted(
            .dateTime
                .month(.abbreviated)
                .day()
                .hour(.defaultDigits(amPM: .abbreviated))
                .minute(.twoDigits)
                .locale(Locale(identifier: "en_US_POSIX"))
        )
    }
}

private struct RoomDetailsTimestamp: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(OceanKeyTheme.secondaryText)
    }
}


#Preview {
    RoomDetailsScreen(route: RoomDetailsRoute(roomID: "303", mode: .voice), workSession: .preview())
        .preferredColorScheme(.dark)
}
