import SwiftUI

struct RoomDetailsScreen: View {
    let route: RoomDetailsRoute
    @Bindable var workSession: WorkSessionStore

    @Environment(\.dismiss) private var dismiss
    @State private var draftText = ""
    @State private var draftVoiceTranscript = ""

    var body: some View {
        ZStack {
            SpriteKitEffectView(.matrixRain)
                .ignoresSafeArea()

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
                        voicePlaceholder
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
            VStack(spacing: 8) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 68, weight: .black))
                    .foregroundStyle(OceanKeyTheme.accent)

                Text("Нативная запись голоса будет подключена отдельным AVFoundation-слоем. Черновик расшифровки уже сохраняется локально.")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 170)

            textEditor(text: $draftVoiceTranscript, placeholder: "Черновик расшифровки")
        }
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

    private var updatedLabel: String? {
        let room = workSession.room(id: route.roomID)
        let date = route.mode == .voice ? room?.voiceTranscriptUpdatedAt : room?.textNoteUpdatedAt
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
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
