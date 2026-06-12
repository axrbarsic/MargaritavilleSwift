import SwiftUI

struct VoiceTranscriptionPanel: View {
    @Environment(\.interactionFeedback) private var feedback

    let title: String
    @Binding var transcript: String
    var onCompletion: VoiceTranscriptionServicing.CompletionHandler? = nil
    @State private var viewModel = VoiceNoteViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: toggleRecording) {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(viewModel.isRecording ? OceanKeyTheme.open : OceanKeyTheme.accent)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(viewModel.isRecording ? "Остановить" : title)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text(viewModel.statusText)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(OceanKeyTheme.secondaryText)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding(14)
                .background(.black.opacity(viewModel.isRecording ? 0.34 : 0.20))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            (viewModel.isRecording ? OceanKeyTheme.open : OceanKeyTheme.accent).opacity(0.28),
                            lineWidth: 1
                        )
                }
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canToggle)
            .opacity(viewModel.canToggle ? 1 : 0.68)

            if viewModel.isRecording {
                Text("Говори по-русски. Текст появится после остановки записи.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText.opacity(0.74))
            }
        }
        .onDisappear {
            viewModel.cancel()
        }
    }

    private func toggleRecording() {
        if viewModel.isRecording {
            feedback.tap()
        } else {
            feedback.holdStart()
        }
        viewModel.toggle(transcript: transcript) { newTranscript in
            transcript = newTranscript
        } onCompletion: { result in
            onCompletion?(result)
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    return VoiceTranscriptionPanel(title: "Голосовая заметка", transcript: $text)
        .padding()
        .background(OceanKeyTheme.background)
}
