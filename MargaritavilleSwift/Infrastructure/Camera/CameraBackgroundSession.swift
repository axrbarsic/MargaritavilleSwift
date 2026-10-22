import AVFoundation
import OSLog

/// Общая сессия задней камеры для фона «Камера». Работает только пока к ней
/// подключён слой предпросмотра активного экрана; вся настройка и запуск идут
/// на собственной очереди, чтобы не блокировать главный поток.
final class CameraBackgroundSession: @unchecked Sendable {
    static let shared = CameraBackgroundSession()

    private static let logger = Logger(
        subsystem: AppIdentity.loggerSubsystem,
        category: "CameraBackground"
    )

    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "\(AppIdentity.bundleIdentifier).camera-background")
    private var isConfigured = false

    static var isAuthorized: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    static var isDenied: Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return status == .denied || status == .restricted
    }

    func start() {
        Task {
            guard await Self.requestAccessIfNeeded() else { return }
            queue.async { [self] in
                configureIfNeeded()
                guard isConfigured, !session.isRunning else { return }
                session.startRunning()
            }
        }
    }

    func stop() {
        queue.async { [self] in
            guard session.isRunning else { return }
            session.stopRunning()
        }
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
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera)
        else {
            Self.logger.error("camera.background.unavailable")
            return
        }
        session.beginConfiguration()
        session.sessionPreset = .inputPriority
        if session.canAddInput(input) {
            session.addInput(input)
        }
        session.commitConfiguration()
        Self.selectSmoothFormat(for: camera)
        isConfigured = session.inputs.contains(input)
    }

    /// Плавный поток для предпросмотра: 1080p на 60 кадрах. Форматы замедленной
    /// съёмки (120–240 кадров) пропускаются: они тяжелее и хуже по качеству.
    private static let targetFrameRate: Double = 60

    private static func selectSmoothFormat(for camera: AVCaptureDevice) {
        let candidates = camera.formats.filter { format in
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            return dimensions.width == 1920 && dimensions.height == 1080 && maxFrameRate(format) >= targetFrameRate
        }
        guard let format = candidates.min(by: { maxFrameRate($0) < maxFrameRate($1) }) else { return }
        let frameRate = targetFrameRate
        do {
            try camera.lockForConfiguration()
            camera.activeFormat = format
            let duration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
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
