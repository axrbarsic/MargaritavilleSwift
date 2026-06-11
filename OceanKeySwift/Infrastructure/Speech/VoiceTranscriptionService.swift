import AVFoundation
import Foundation
import OSLog
import Speech

private enum VoiceTranscriptionError: LocalizedError {
    case recorderUnavailable

    var errorDescription: String? {
        switch self {
        case .recorderUnavailable:
            "Не удалось запустить запись"
        }
    }
}

/// Потокобезопасный однократный «затвор» для `CheckedContinuation`: гарантирует
/// ровно один `resume`, даже если колбэк Speech придёт несколько раз или с
/// разных потоков.
private final class ResumeGuard: @unchecked Sendable {
    private let lock = NSLock()
    private var done = false

    func claim() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if done { return false }
        done = true
        return true
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

/// Запись голосовой заметки и расшифровка ПО ФАЙЛУ — надёжный Apple-путь:
/// `AVAudioRecorder` пишет m4a, после остановки `SFSpeechURLRecognitionRequest`
/// расшифровывает файл. Сознательно НЕ используется живой
/// `AVAudioEngine`+`installTap`+live-Speech — именно живой аудио-tap c
/// одновременным распознаванием ронял приложение на реальном устройстве.
@MainActor
final class VoiceTranscriptionService: VoiceTranscriptionServicing {
    private static let logger = Logger(
        subsystem: "com.alex.margaritaville.swift",
        category: "VoiceTranscription"
    )

    private let recognizer: SFSpeechRecognizer?
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var activeSessionID: UUID?
    private var baseText = ""
    private var onTranscript: TranscriptHandler?
    private var onCompletion: CompletionHandler?
    private var onStatus: StatusHandler?
    private var onPhase: PhaseHandler?

    private var phase = VoiceCapturePhase.idle {
        didSet { onPhase?(phase) }
    }

    init(locale: Locale = Locale(identifier: "ru-RU")) {
        recognizer = SFSpeechRecognizer(locale: locale)
    }

    func start(
        baseText: String,
        onTranscript: @escaping TranscriptHandler,
        onCompletion: CompletionHandler?,
        onStatus: @escaping StatusHandler,
        onPhase: @escaping PhaseHandler
    ) async {
        guard phase.canToggle, !phase.isRecording else { return }
        cleanup(deleteFile: true)

        let sessionID = UUID()
        activeSessionID = sessionID
        self.baseText = baseText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.onTranscript = onTranscript
        self.onCompletion = onCompletion
        self.onStatus = onStatus
        self.onPhase = onPhase

        phase = .requestingPermission
        onStatus("Проверяю доступ...")

        guard await requestSpeechRecognitionPermission() else {
            fail("Нет доступа к распознаванию речи")
            return
        }
        guard isCurrent(sessionID) else { return }
        guard await requestMicrophonePermission() else {
            fail("Нет доступа к микрофону")
            return
        }
        guard isCurrent(sessionID) else { return }

        phase = .starting
        onStatus("Запускаю микрофон...")
        do {
            try beginRecording()
            guard isCurrent(sessionID) else {
                cleanup(deleteFile: true)
                return
            }
            phase = .recording
            onStatus("Идёт запись...")
            Self.logger.info("voice.recording.file")
        } catch {
            Self.logger.error("voice.start.failed \(error.localizedDescription, privacy: .public)")
            fail("Ошибка микрофона: \(error.localizedDescription)")
        }
    }

    func stop() {
        guard phase == .recording || phase == .starting else { return }
        phase = .finishing
        onStatus?("Завершаю расшифровку...")

        let url = recordingURL
        recorder?.stop()
        recorder = nil
        recordingURL = nil
        deactivateSession()

        guard let url else {
            finishIfCurrent(activeSessionID, status: "Нет записи", transcript: nil, audioURL: nil)
            return
        }
        let sessionID = activeSessionID
        Task { [weak self] in
            await self?.transcribe(url: url, sessionID: sessionID)
        }
    }

    func cancel() {
        cleanup(deleteFile: true)
        phase = .idle
        onStatus?("Готово к записи")
    }

    // MARK: - Recording

    private func beginRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default, options: [])
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("voice-\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        guard recorder.record() else {
            throw VoiceTranscriptionError.recorderUnavailable
        }
        self.recorder = recorder
        recordingURL = url
    }

    // MARK: - File-based transcription

    private func transcribe(url: URL, sessionID: UUID?) async {
        guard let recognizer, recognizer.isAvailable else {
            finishIfCurrent(sessionID, status: "Распознавание недоступно", transcript: nil, audioURL: url)
            return
        }
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation
        if #available(iOS 16.0, *) {
            request.addsPunctuation = true
        }

        let transcript = await recognizeOnce(recognizer: recognizer, request: request)
        finishIfCurrent(
            sessionID,
            status: (transcript?.isEmpty == false) ? "Готово" : "Нет распознанного текста",
            transcript: transcript,
            audioURL: url
        )
    }

    private func recognizeOnce(
        recognizer: SFSpeechRecognizer,
        request: SFSpeechURLRecognitionRequest
    ) async -> String? {
        let resumeGuard = ResumeGuard()
        return await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
            recognizer.recognitionTask(with: request) { result, error in
                if let result, result.isFinal {
                    if resumeGuard.claim() {
                        continuation.resume(returning: result.bestTranscription.formattedString)
                    }
                } else if error != nil {
                    if resumeGuard.claim() {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }

    // MARK: - Lifecycle helpers

    private func deliver(_ recognized: String) {
        let clean = recognized.trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = [baseText, clean]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        guard !combined.isEmpty else { return }
        onTranscript?(combined)
    }

    private func finishIfCurrent(_ sessionID: UUID?, status: String, transcript: String?, audioURL: URL?) {
        guard isCurrent(sessionID) else { return }
        if let transcript { deliver(transcript) }
        if let audioURL {
            onCompletion?(VoiceTranscriptionResult(transcript: transcript, audioURL: audioURL))
        }
        activeSessionID = nil
        phase = .idle
        onStatus?(status)
        Self.logger.info("voice.finish \(status, privacy: .public)")
    }

    private func fail(_ message: String) {
        Self.logger.error("voice.fail \(message, privacy: .public)")
        cleanup(deleteFile: true)
        phase = .failed(message)
        onStatus?(message)
    }

    private func cleanup(deleteFile: Bool) {
        recorder?.stop()
        recorder = nil
        if deleteFile, let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
        deactivateSession()
        activeSessionID = nil
    }

    private func deactivateSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            // Деактивация не критична: запись уже остановлена.
        }
    }

    private func isCurrent(_ sessionID: UUID?) -> Bool {
        sessionID != nil && activeSessionID == sessionID
    }
}
