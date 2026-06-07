import AVFoundation
import OSLog
import Speech

private enum VoiceTranscriptionError: LocalizedError {
    case invalidInputFormat

    var errorDescription: String? {
        switch self {
        case .invalidInputFormat:
            "Микрофон не отдал аудио-формат"
        }
    }
}

private func requestSpeechRecognitionPermission() async -> Bool {
    await withCheckedContinuation { continuation in
        SFSpeechRecognizer.requestAuthorization { status in
            continuation.resume(returning: status == .authorized)
        }
    }
}

private func requestMicrophonePermission() async -> Bool {
    await withCheckedContinuation { continuation in
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
    }
}

@MainActor
final class VoiceTranscriptionService: VoiceTranscriptionServicing {
    private static let logger = Logger(subsystem: "com.alex.oceankey.swift", category: "VoiceTranscription")

    private let recognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioPipe: SpeechAudioBufferPipe?
    private var cleanupTask: Task<Void, Never>?
    private var baseText = ""
    private var activeSessionID: UUID?
    private var hasInstalledTap = false
    private var hasDeliveredTranscript = false
    private var onTranscript: TranscriptHandler?
    private var onStatus: StatusHandler?
    private var onPhase: PhaseHandler?

    private(set) var phase = VoiceCapturePhase.idle {
        didSet { onPhase?(phase) }
    }

    init(locale: Locale = Locale(identifier: "ru-RU")) {
        recognizer = SFSpeechRecognizer(locale: locale)
    }

    func start(
        baseText: String,
        onTranscript: @escaping TranscriptHandler,
        onStatus: @escaping StatusHandler,
        onPhase: @escaping PhaseHandler
    ) async {
        guard phase.canToggle, phase != .recording else { return }
        cleanupExistingSession(cancelTask: true)

        let sessionID = UUID()
        activeSessionID = sessionID
        self.baseText = baseText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.onTranscript = onTranscript
        self.onStatus = onStatus
        self.onPhase = onPhase
        hasDeliveredTranscript = false

        phase = .requestingPermission
        Self.logger.info("voice.start permission")
        onStatus("Проверяю доступ...")

        let speechAllowed = await requestSpeechRecognitionPermission()
        guard isCurrentSession(sessionID) else { return }
        guard speechAllowed else {
            fail("Нет доступа к распознаванию речи")
            return
        }

        let micAllowed = await requestMicrophonePermission()
        guard isCurrentSession(sessionID) else { return }
        guard micAllowed else {
            fail("Нет доступа к микрофону")
            return
        }

        guard let recognizer else {
            fail("Русское распознавание речи недоступно")
            return
        }
        guard recognizer.isAvailable else {
            fail("Распознавание речи недоступно")
            return
        }

        phase = .starting
        Self.logger.info("voice.start audio")
        onStatus("Запускаю микрофон...")

        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        request.addsPunctuation = true
        let audioPipe = SpeechAudioBufferPipe(request: request)

        audioEngine = engine
        recognitionRequest = request
        self.audioPipe = audioPipe

        do {
            try configureRecordingSession()
            try installAudioTap(on: engine, audioPipe: audioPipe)
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    self?.handleRecognition(result: result, error: error)
                }
            }
            engine.prepare()
            try engine.start()
            guard isCurrentSession(sessionID) else { return }
            phase = .recording
            Self.logger.info("voice.recording")
            onStatus("Слушаю...")
        } catch {
            Self.logger.error("voice.start.failed \(error.localizedDescription, privacy: .public)")
            fail("Ошибка микрофона: \(error.localizedDescription)")
        }
    }

    func stop() {
        guard phase == .recording || phase == .starting else { return }
        phase = .finishing
        Self.logger.info("voice.stop")
        onStatus?("Завершаю расшифровку...")
        audioPipe?.finishAudio()
        stopAudioEngine()
        scheduleFinishingTimeout()
    }

    func cancel() {
        cleanupExistingSession(cancelTask: true)
        phase = .idle
        onStatus?("Готово к записи")
        restoreInteractionAudioSession()
    }

    private func handleRecognition(result: SFSpeechRecognitionResult?, error: Error?) {
        guard phase == .recording || phase == .finishing || phase == .starting else { return }

        if let result {
            deliver(result.bestTranscription.formattedString)
            onStatus?(result.isFinal ? "Готово" : "Слушаю...")
            if result.isFinal {
                finish(status: "Готово", cancelTask: false)
                return
            }
        }

        if let error {
            let status = hasDeliveredTranscript
                ? "Расшифровка сохранена"
                : "Распознавание: \(error.localizedDescription)"
            finish(status: status, cancelTask: true)
        }
    }

    private func deliver(_ recognized: String) {
        let cleanRecognized = recognized.trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = [baseText, cleanRecognized]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        guard !combined.isEmpty else { return }
        hasDeliveredTranscript = true
        onTranscript?(combined)
    }

    private func scheduleFinishingTimeout() {
        cleanupTask?.cancel()
        cleanupTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.4))
            await MainActor.run {
                guard let self, self.phase == .finishing else { return }
                self.finish(status: self.hasDeliveredTranscript ? "Расшифровка сохранена" : "Нет распознанного текста", cancelTask: false)
            }
        }
    }

    private func finish(status: String, cancelTask: Bool) {
        cleanupTask?.cancel()
        cleanupTask = nil
        cleanupExistingSession(cancelTask: cancelTask)
        phase = .idle
        Self.logger.info("voice.finish \(status, privacy: .public)")
        onStatus?(status)
        restoreInteractionAudioSession()
    }

    private func fail(_ message: String) {
        Self.logger.error("voice.fail \(message, privacy: .public)")
        cleanupExistingSession(cancelTask: true)
        phase = .failed(message)
        onStatus?(message)
        restoreInteractionAudioSession()
    }

    private func cleanupExistingSession(cancelTask: Bool) {
        cleanupTask?.cancel()
        cleanupTask = nil
        audioPipe?.finishAudio()
        stopAudioEngine()
        if cancelTask {
            recognitionTask?.cancel()
        }
        recognitionTask = nil
        recognitionRequest = nil
        audioPipe?.discard()
        audioPipe = nil
        activeSessionID = nil
        hasDeliveredTranscript = false
    }

    private func isCurrentSession(_ sessionID: UUID) -> Bool {
        activeSessionID == sessionID
    }

    private func configureRecordingSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .record,
            mode: .measurement,
            options: []
        )
        try session.setActive(true)
    }

    private func restoreInteractionAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            onStatus?("Запись остановлена")
        }
    }

    private func installAudioTap(on engine: AVAudioEngine, audioPipe: SpeechAudioBufferPipe) throws {
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw VoiceTranscriptionError.invalidInputFormat
        }
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { buffer, _ in
            audioPipe.append(buffer)
        }
        hasInstalledTap = true
    }

    private func stopAudioEngine() {
        guard let engine = audioEngine else { return }
        if engine.isRunning {
            engine.stop()
        }
        if hasInstalledTap {
            engine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        audioEngine = nil
    }
}
