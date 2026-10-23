import AVFoundation
import OSLog

/// Общая сессия задней камеры для фона «Камера». Кадры идут через
/// `AVCaptureVideoDataOutput` прямо в Metal-рендер активного экрана.
/// Главный поток только сообщает, какой экран активен: настройка, запуск,
/// остановка и отрисовка кадров идут на собственных очередях.
final class CameraBackgroundSession: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    static let shared = CameraBackgroundSession()

    private static let logger = Logger(
        subsystem: AppIdentity.loggerSubsystem,
        category: "CameraBackground"
    )
    /// Пауза перед остановкой: при переходе между экранами камера не перезапускается.
    private static let stopDelay: TimeInterval = 0.6
    private static let targetFrameRate: Double = 60

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "\(AppIdentity.bundleIdentifier).camera-session")
    private let frameQueue = DispatchQueue(label: "\(AppIdentity.bundleIdentifier).camera-frames", qos: .userInteractive)
    private let lock = NSLock()
    private var target: CameraRenderTarget?
    private var generation = 0
    private var isConfigured = false
    /// Камера, которую последней запросил экран (читается под замком на главном).
    private var requestedPosition: CameraBackgroundPosition = .back
    /// Камера, подключённая к сессии сейчас (только на очереди сессии).
    private var activePosition: CameraBackgroundPosition = .back
    private var currentInput: AVCaptureDeviceInput?
    private lazy var renderer: CameraBackgroundRenderer? = CameraBackgroundRenderer()

    static var isDenied: Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return status == .denied || status == .restricted
    }

    func attach(_ target: CameraRenderTarget) {
        let shouldStart: Bool = locked {
            generation += 1
            let changed = self.target !== target
            self.target = target
            return changed
        }
        guard shouldStart else { return }
        Task {
            guard await Self.requestAccessIfNeeded() else { return }
            sessionQueue.async { [self] in
                configureIfNeeded()
                guard isConfigured, !session.isRunning else { return }
                session.startRunning()
            }
        }
    }

    /// Переключает камеру без перезапуска сессии: меняется только вход.
    func setPosition(_ position: CameraBackgroundPosition) {
        let changed: Bool = locked {
            guard requestedPosition != position else { return false }
            requestedPosition = position
            return true
        }
        guard changed else { return }
        sessionQueue.async { [self] in
            guard isConfigured else {
                activePosition = position
                return
            }
            switchInput(to: position)
        }
    }

    func detach(_ target: CameraRenderTarget) {
        let stopGeneration: Int? = locked {
            guard self.target === target else { return nil }
            self.target = nil
            generation += 1
            return generation
        }
        guard let stopGeneration else { return }
        sessionQueue.asyncAfter(deadline: .now() + Self.stopDelay) { [self] in
            let stillIdle = locked { self.target == nil && generation == stopGeneration }
            guard stillIdle, session.isRunning else { return }
            session.stopRunning()
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let target = locked({ self.target }),
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }
        renderer?.render(pixelBuffer, to: target)
    }

    private func locked<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    private static func requestAccessIfNeeded() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: true
        case .notDetermined: await AVCaptureDevice.requestAccess(for: .video)
        default: false
        }
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        guard let input = Self.makeInput(for: activePosition) else {
            Self.logger.error("camera.background.unavailable")
            return
        }
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: frameQueue)

        session.beginConfiguration()
        session.sessionPreset = .inputPriority
        guard session.canAddInput(input), session.canAddOutput(output) else {
            session.commitConfiguration()
            Self.logger.error("camera.background.configuration")
            return
        }
        session.addInput(input)
        session.addOutput(output)
        currentInput = input
        session.commitConfiguration()
        applyConnectionSettings()
        Self.selectSmoothFormat(for: input.device)
        isConfigured = true
    }

    private func switchInput(to position: CameraBackgroundPosition) {
        guard position != activePosition, let input = Self.makeInput(for: position) else { return }
        session.beginConfiguration()
        if let currentInput {
            session.removeInput(currentInput)
        }
        if session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
            activePosition = position
        } else if let currentInput {
            session.addInput(currentInput)
            Self.logger.error("camera.background.switch-failed")
        }
        session.commitConfiguration()
        // Соединение пересоздаётся при смене входа, поэтому поворот и зеркало
        // выставляются уже после commitConfiguration.
        applyConnectionSettings()
        if let device = currentInput?.device {
            Self.selectSmoothFormat(for: device)
        }
    }

    /// Портретная ориентация кадра и зеркало для передней камеры.
    private func applyConnectionSettings() {
        guard let connection = output.connection(with: .video) else { return }
        // Интерфейс всегда портретный: обе камеры поворачиваются на 90°.
        if connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = activePosition.isMirrored
        }
    }

    private static func makeInput(for position: CameraBackgroundPosition) -> AVCaptureDeviceInput? {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position.devicePosition) else {
            return nil
        }
        return try? AVCaptureDeviceInput(device: camera)
    }

    /// 1080p на 60 кадрах. Форматы замедленной съёмки (120–240 кадров)
    /// пропускаются: они тяжелее и хуже по качеству.
    private static func selectSmoothFormat(for camera: AVCaptureDevice) {
        let candidates = camera.formats.filter { format in
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            return dimensions.width == 1920 && dimensions.height == 1080 && maxFrameRate(format) >= targetFrameRate
        }
        guard let format = candidates.min(by: { maxFrameRate($0) < maxFrameRate($1) }) else { return }
        do {
            try camera.lockForConfiguration()
            camera.activeFormat = format
            let duration = CMTime(value: 1, timescale: CMTimeScale(targetFrameRate))
            camera.activeVideoMinFrameDuration = duration
            camera.activeVideoMaxFrameDuration = duration
            camera.unlockForConfiguration()
        } catch {
            logger.error("camera.background.format \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func maxFrameRate(_ format: AVCaptureDevice.Format) -> Double {
        format.videoSupportedFrameRateRanges.map(\.maxFrameRate).max() ?? 0
    }
}
