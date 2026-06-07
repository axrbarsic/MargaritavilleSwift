import AVFoundation
import Speech

final class SpeechAudioBufferPipe {
    private let lock = NSLock()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var didFinish = false

    init(request: SFSpeechAudioBufferRecognitionRequest) {
        self.request = request
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        defer { lock.unlock() }
        guard let request, !didFinish else { return }
        request.append(buffer)
    }

    func finishAudio() {
        lock.lock()
        defer { lock.unlock() }
        guard let request, !didFinish else { return }
        didFinish = true
        request.endAudio()
    }

    func discard() {
        lock.lock()
        defer { lock.unlock() }
        didFinish = true
        request = nil
    }
}
