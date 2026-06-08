import Foundation

enum VoiceCapturePhase: Equatable {
    case idle
    case requestingPermission
    case starting
    case recording
    case finishing
    case failed(String)

    var isRecording: Bool {
        self == .recording
    }

    var canToggle: Bool {
        switch self {
        case .idle, .recording, .failed:
            true
        case .requestingPermission, .starting, .finishing:
            false
        }
    }
}

struct VoiceTranscriptionResult {
    let transcript: String?
    let audioURL: URL
}

@MainActor
protocol VoiceTranscriptionServicing: AnyObject {
    typealias TranscriptHandler = @MainActor (String) -> Void
    typealias CompletionHandler = @MainActor (VoiceTranscriptionResult) -> Void
    typealias StatusHandler = @MainActor (String) -> Void
    typealias PhaseHandler = @MainActor (VoiceCapturePhase) -> Void

    func start(
        baseText: String,
        onTranscript: @escaping TranscriptHandler,
        onCompletion: CompletionHandler?,
        onStatus: @escaping StatusHandler,
        onPhase: @escaping PhaseHandler
    ) async
    func stop()
    func cancel()
}
