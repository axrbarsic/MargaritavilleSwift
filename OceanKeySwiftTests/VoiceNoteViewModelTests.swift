import Testing
@testable import OceanKeySwift

@MainActor
@Test
func voiceNoteViewModelReflectsRecordingPhase() async {
    let service = FakeVoiceTranscriptionService()
    let viewModel = VoiceNoteViewModel(service: service)

    viewModel.toggle(transcript: "") { _ in }
    await service.waitForStart()

    service.phaseHandler?(.recording)

    #expect(viewModel.isRecording == true)
    #expect(viewModel.canToggle == true)
}

@MainActor
@Test
func voiceNoteViewModelForwardsTranscript() async {
    let service = FakeVoiceTranscriptionService()
    let viewModel = VoiceNoteViewModel(service: service)
    var transcript = ""

    viewModel.toggle(transcript: "old") { transcript = $0 }
    await service.waitForStart()

    service.transcriptHandler?("old\nновый текст")

    #expect(transcript == "old\nновый текст")
}

@MainActor
@Test
func voiceNoteViewModelBlocksToggleWhileStarting() async {
    let service = FakeVoiceTranscriptionService()
    let viewModel = VoiceNoteViewModel(service: service)

    viewModel.toggle(transcript: "") { _ in }
    await service.waitForStart()

    service.phaseHandler?(.starting)
    viewModel.toggle(transcript: "") { _ in }

    #expect(service.startCount == 1)
    #expect(viewModel.canToggle == false)
}

@MainActor
private final class FakeVoiceTranscriptionService: VoiceTranscriptionServicing {
    var transcriptHandler: TranscriptHandler?
    var statusHandler: StatusHandler?
    var phaseHandler: PhaseHandler?
    var startCount = 0
    private var startContinuation: CheckedContinuation<Void, Never>?

    func start(
        baseText: String,
        onTranscript: @escaping TranscriptHandler,
        onCompletion: CompletionHandler?,
        onStatus: @escaping StatusHandler,
        onPhase: @escaping PhaseHandler
    ) async {
        startCount += 1
        transcriptHandler = onTranscript
        statusHandler = onStatus
        phaseHandler = onPhase
        startContinuation?.resume()
        startContinuation = nil
    }

    func stop() {
        phaseHandler?(.idle)
    }

    func cancel() {
        phaseHandler?(.idle)
    }

    func waitForStart() async {
        guard startCount == 0 else { return }
        await withCheckedContinuation { continuation in
            startContinuation = continuation
        }
    }
}
