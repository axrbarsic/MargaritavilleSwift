import SwiftUI

struct CartDetailsScreen: View {
    let route: CartDetailsRoute
    @Bindable var workSession: WorkSessionStore

    @Environment(\.dismiss) private var dismiss
    @State private var draftNote = ""
    @State private var captureKind: MediaKind?
    @State private var mediaError: String?

    var body: some View {
        ZStack {
            SpriteKitEffectView(.matrixRain)
                .ignoresSafeArea()

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
        }
        .onAppear(perform: loadDraft)
        .onChange(of: draftNote) { _, newValue in
            workSession.updateCartNote(newValue, cartId: route.cartID)
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
                Text("Тележка \(route.cartID)")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)

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
            VoiceTranscriptionPanel(title: "Надиктовать заметку", transcript: $draftNote)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $draftNote)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(.white)
                    .padding(10)
                    .frame(minHeight: 180)
                    .background(.black.opacity(0.24))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                if draftNote.isEmpty {
                    Text("Что принести на тележку, что уже проверено, что нужно уточнить...")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(OceanKeyTheme.secondaryText.opacity(0.52))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private var consumablesSection: some View {
        CartDetailsPanel(title: "Расходники") {
            CartConsumablesSection(cartID: route.cartID, workSession: workSession)
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

            if mediaAttachments.isEmpty {
                Text("Фото и видео сохраняются только локально на устройстве.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(mediaAttachments) { attachment in
                            MediaThumbnailView(attachment: attachment)
                        }
                    }
                }
            }
        }
        .fullScreenCover(item: $captureKind) { kind in
            CameraCaptureView(
                kind: kind,
                onCapture: saveCapturedMedia,
                onCancel: { captureKind = nil }
            )
            .ignoresSafeArea()
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

    private func loadDraft() {
        draftNote = workSession.cart(id: route.cartID)?.note ?? ""
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

    private var updatedLabel: String? {
        guard let date = workSession.cart(id: route.cartID)?.noteUpdatedAt else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
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
    CartDetailsScreen(route: CartDetailsRoute(cartID: 7), workSession: .preview())
        .preferredColorScheme(.dark)
}
