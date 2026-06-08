import Observation

@MainActor
@Observable
final class VoiceNoteViewModel {
    private let service: any VoiceTranscriptionServicing

    private(set) var isRecording = false
    private(set) var canToggle = true
    private(set) var statusText = "Готово к записи"

    init(service: any VoiceTranscriptionServicing = VoiceTranscriptionService()) {
        self.service = service
    }

    func toggle(
        transcript: String,
        onTranscript: @escaping @MainActor (String) -> Void,
        onCompletion: VoiceTranscriptionServicing.CompletionHandler? = nil
    ) {
        guard canToggle else { return }
        if isRecording {
            service.stop()
        } else {
            Task {
                await service.start(
                    baseText: transcript,
                    onTranscript: onTranscript,
                    onCompletion: onCompletion,
                    onStatus: updateStatus,
                    onPhase: updatePhase
                )
            }
        }
    }

    func cancel() {
        service.cancel()
        isRecording = false
        canToggle = true
        statusText = "Готово к записи"
    }

    private func updateStatus(_ status: String) {
        statusText = status
    }

    private func updatePhase(_ phase: VoiceCapturePhase) {
        isRecording = phase.isRecording
        canToggle = phase.canToggle
        if case .failed(let message) = phase {
            statusText = message
        }
    }
}
