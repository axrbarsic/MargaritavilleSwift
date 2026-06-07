import AVFoundation
import Observation
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
@Observable
final class VoiceTranscriptionController {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var baseText = ""
    private var onTranscript: ((String) -> Void)?
    private var hasInstalledTap = false

    private(set) var isRecording = false
    private(set) var statusText = "Готово к записи"

    func toggle(transcript: String, onTranscript: @escaping (String) -> Void) {
        if isRecording {
            stop()
        } else {
            Task {
                await start(transcript: transcript, onTranscript: onTranscript)
            }
        }
    }

    func stop() {
        finishRecording(status: "Расшифровка сохранена", cancelTask: false)
    }

    private func start(transcript: String, onTranscript: @escaping (String) -> Void) async {
        guard await requestPermissions() else { return }
        guard let recognizer else {
            statusText = "Русское распознавание речи недоступно"
            return
        }
        guard recognizer.isAvailable else {
            statusText = "Распознавание речи недоступно"
            return
        }

        stopExistingTask()
        baseText = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        self.onTranscript = onTranscript

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        do {
            try configureRecordingSession()
            try installAudioTap(request: request)
            audioEngine.prepare()
            try audioEngine.start()
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    self?.handleRecognition(result: result, error: error)
                }
            }
            isRecording = true
            statusText = "Слушаю..."
        } catch {
            statusText = "Ошибка микрофона: \(error.localizedDescription)"
            finishRecording(status: statusText, cancelTask: true)
        }
    }

    private func requestPermissions() async -> Bool {
        statusText = "Проверяю доступ..."
        let speechAllowed = await requestSpeechRecognitionPermission()
        guard speechAllowed else {
            statusText = "Нет доступа к распознаванию речи"
            return false
        }

        let micAllowed = await requestMicrophonePermission()
        guard micAllowed else {
            statusText = "Нет доступа к микрофону"
            return false
        }
        return true
    }

    private func configureRecordingSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.allowBluetoothHFP, .defaultToSpeaker, .mixWithOthers]
        )
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func restoreInteractionAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            statusText = "Запись остановлена"
        }
    }

    private func installAudioTap(request: SFSpeechAudioBufferRecognitionRequest) throws {
        let inputNode = audioEngine.inputNode
        if hasInstalledTap {
            inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw VoiceTranscriptionError.invalidInputFormat
        }
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { buffer, _ in
            request.append(buffer)
        }
        hasInstalledTap = true
    }

    private func handleRecognition(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result {
            let recognized = result.bestTranscription.formattedString
            let combined = [baseText, recognized]
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            onTranscript?(combined)
            statusText = result.isFinal ? "Готово" : "Слушаю..."
        }
        if error != nil, isRecording {
            finishRecording(status: "Распознавание остановлено", cancelTask: true)
        }
    }

    private func stopExistingTask() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        stopAudioEngine()
        isRecording = false
    }

    private func finishRecording(status: String, cancelTask: Bool) {
        let request = recognitionRequest
        let task = recognitionTask
        isRecording = false
        statusText = status
        stopAudioEngine()
        request?.endAudio()
        if cancelTask {
            task?.cancel()
        }
        recognitionTask = nil
        recognitionRequest = nil
        restoreInteractionAudioSession()
    }

    private func stopAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
    }
}
