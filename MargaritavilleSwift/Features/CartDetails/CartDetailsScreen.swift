import SwiftUI

struct CartDetailsScreen: View {
    let route: CartDetailsRoute
    @Bindable var workSession: WorkSessionStore
    @Bindable var appSettings: AppSettingsStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.interactionFeedback) private var feedback
    @State private var draftNote = ""
    @State private var draftVoiceTranscript = ""
    @State private var captureKind: MediaKind?
    @State private var selectedMedia: MediaAttachment?
    @State private var mediaPreviewPlaybackEnabled = true
    @State private var mediaError: String?
    @State private var activeQuantityPicker: CartQuantityPickerState?

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    noteSection
                    consumablesSection
                    mediaSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)

            if let activeQuantityPicker {
                QuantityRadialPickerOverlay(
                    title: activeQuantityPicker.title,
                    selectedQuantity: activeQuantityPicker.quantity,
                    onQuantityChange: updateActiveQuantity,
                    onCommit: commitActiveQuantity,
                    onCancel: cancelActiveQuantity
                )
                .zIndex(4)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .onAppear(perform: loadDraft)
        .onChange(of: draftNote) { _, newValue in
            workSession.updateCartNote(newValue, cartId: route.cartID)
        }
        .onChange(of: draftVoiceTranscript) { _, newValue in
            workSession.updateCartNote(newValue, cartId: route.cartID)
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

            VStack(alignment: .leading, spacing: 2) {
                Text(route.title ?? "Тележка \(route.cartID)")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)

                if let subtitle = route.subtitle {
                    Text(subtitle)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(OceanKeyTheme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                }

                if let updatedLabel {
                    Text("Обновлено: \(updatedLabel)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(OceanKeyTheme.secondaryText)
                }
            }
        }
    }

    private var noteSection: some View {
        CartDetailsPanel(title: "Заметка") {
            VoiceTranscriptionPanel(
                title: "Голосовая заметка",
                transcript: $draftVoiceTranscript,
                onCompletion: saveVoiceResult
            )

            if voiceAttachments.isEmpty {
                Text("Голосовые заметки по тележке появятся здесь пузырями после записи.")
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

    private var consumablesSection: some View {
        CartDetailsPanel(title: "Расходники") {
            CartConsumablesSection(
                cartID: route.cartID,
                workSession: workSession,
                catalog: appSettings.cartConsumableCatalog,
                onQuantityPickerRequested: openQuantityPicker
            )
        }
    }

    private var mediaSection: some View {
        CartDetailsPanel(title: "Медиа") {
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
                Text("Фото и видео сохраняются только локально на устройстве.")
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

    private var mediaAttachments: [MediaAttachment] {
        workSession.cart(id: route.cartID)?.mediaAttachments ?? []
    }

    private var visualMediaAttachments: [MediaAttachment] {
        mediaAttachments.filter { $0.kind == .photo || $0.kind == .video }
    }

    private var voiceAttachments: [MediaAttachment] {
        mediaAttachments.filter { $0.kind == .audio }
    }

    private func loadDraft() {
        draftNote = workSession.cart(id: route.cartID)?.note ?? ""
        draftVoiceTranscript = draftNote
    }

    private func saveCapturedMedia(_ capturedMedia: CapturedMedia) {
        do {
            let attachment = try LocalMediaFileStore().save(capturedMedia: capturedMedia)
            workSession.addCartMedia(attachment, cartId: route.cartID)
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
            workSession.addCartMedia(attachment, cartId: route.cartID)
            if let transcript = result.transcript, !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draftNote = transcript
                draftVoiceTranscript = transcript
            }
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
        workSession.removeCartMedia(attachment, cartId: route.cartID)
        loadDraft()
    }

    private func openMediaAttachment(_ attachment: MediaAttachment) {
        mediaPreviewPlaybackEnabled = false
        selectedMedia = attachment
    }

    private func openQuantityPicker(_ item: CartConsumableItem) {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.86)) {
            activeQuantityPicker = CartQuantityPickerState(
                itemID: item.id,
                title: item.title,
                quantity: max(1, min(item.quantity == 0 ? 1 : item.quantity, 10))
            )
        }
    }

    private func updateActiveQuantity(_ quantity: Int) {
        let quantity = max(1, min(quantity, 10))
        guard activeQuantityPicker?.quantity != quantity else { return }
        activeQuantityPicker?.quantity = quantity
        feedback.select()
    }

    private func commitActiveQuantity(_ quantity: Int) {
        guard let picker = activeQuantityPicker else { return }
        workSession.updateCartConsumableQuantity(
            itemID: picker.itemID,
            title: picker.title,
            quantity: max(1, min(quantity, 10)),
            cartId: route.cartID
        )
        feedback.holdCommit()
        withAnimation(.spring(response: 0.20, dampingFraction: 0.88)) {
            activeQuantityPicker = nil
        }
    }

    private func cancelActiveQuantity() {
        feedback.deselect()
        withAnimation(.spring(response: 0.20, dampingFraction: 0.88)) {
            activeQuantityPicker = nil
        }
    }

    private var updatedLabel: String? {
        guard let date = workSession.cart(id: route.cartID)?.noteUpdatedAt else { return nil }
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

private struct CartQuantityPickerState: Identifiable {
    let itemID: CartConsumableItem.ID
    let title: String
    var quantity: Int

    var id: CartConsumableItem.ID { itemID }
}

private struct CartDetailsPanel<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

#Preview {
    CartDetailsScreen(
        route: CartDetailsRoute(cartID: 7),
        workSession: .preview(),
        appSettings: AppSettingsStore()
    )
        .preferredColorScheme(.dark)
}
