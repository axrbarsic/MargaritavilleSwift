import SwiftUI
import UIKit
import AVFoundation
import UniformTypeIdentifiers

enum CapturedMedia {
    case photo(UIImage)
    case video(URL)
}

struct CameraCaptureView: UIViewControllerRepresentable {
    let kind: MediaKind
    let onCapture: (CapturedMedia) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        CameraCaptureHostViewController(
            kind: kind,
            coordinator: context.coordinator,
            onCancel: onCancel
        )
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(kind: kind, onCapture: onCapture, onCancel: onCancel)
    }
}

extension CameraCaptureView {
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let kind: MediaKind
        private let onCapture: (CapturedMedia) -> Void
        private let onCancel: () -> Void

        init(kind: MediaKind, onCapture: @escaping (CapturedMedia) -> Void, onCancel: @escaping () -> Void) {
            self.kind = kind
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) { [onCancel] in
                onCancel()
            }
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            switch kind {
            case .photo:
                guard let image = info[.originalImage] as? UIImage else {
                    picker.dismiss(animated: true) { [onCancel] in
                        onCancel()
                    }
                    return
                }
                picker.dismiss(animated: true) { [onCapture] in
                    onCapture(.photo(image))
                }
            case .video:
                guard let url = info[.mediaURL] as? URL else {
                    picker.dismiss(animated: true) { [onCancel] in
                        onCancel()
                    }
                    return
                }
                let stableURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("captured-\(UUID().uuidString).mov")
                do {
                    if FileManager.default.fileExists(atPath: stableURL.path) {
                        try FileManager.default.removeItem(at: stableURL)
                    }
                    try FileManager.default.copyItem(at: url, to: stableURL)
                    picker.dismiss(animated: true) { [onCapture] in
                        onCapture(.video(stableURL))
                    }
                } catch {
                    picker.dismiss(animated: true) { [onCancel] in
                        onCancel()
                    }
                }
            case .audio:
                picker.dismiss(animated: true) { [onCancel] in
                    onCancel()
                }
            }
        }
    }
}

private final class CameraCaptureHostViewController: UIViewController {
    private enum State {
        case idle
        case requestingPermission
        case presentingPicker
        case finished
    }

    private let kind: MediaKind
    private let coordinator: CameraCaptureView.Coordinator
    private let onCancel: () -> Void
    private var state = State.idle

    init(
        kind: MediaKind,
        coordinator: CameraCaptureView.Coordinator,
        onCancel: @escaping () -> Void
    ) {
        self.kind = kind
        self.coordinator = coordinator
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startIfNeeded()
    }

    private func startIfNeeded() {
        guard state == .idle else { return }
        guard kind == .photo || kind == .video else {
            showUnavailable("Этот режим камеры недоступен")
            return
        }
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showUnavailable("Камера недоступна")
            return
        }

        state = .requestingPermission
        Task { @MainActor in
            let hasCameraAccess = await requestAccess(for: .video)
            let hasAudioAccess = kind == .video ? await requestAccess(for: .audio) : true
            guard state == .requestingPermission else { return }
            guard hasCameraAccess else {
                showUnavailable("Нет доступа к камере")
                return
            }
            guard hasAudioAccess else {
                showUnavailable("Нет доступа к микрофону для видео")
                return
            }
            presentPicker()
        }
    }

    private func presentPicker() {
        let requestedType = kind == .photo ? UTType.image.identifier : UTType.movie.identifier
        let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera) ?? []
        guard availableTypes.contains(requestedType) else {
            showUnavailable("Этот режим камеры недоступен")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = coordinator
        picker.mediaTypes = [requestedType]
        picker.videoQuality = .typeHigh
        picker.videoMaximumDuration = 60 * 10
        picker.allowsEditing = false
        picker.cameraCaptureMode = kind == .photo ? .photo : .video
        picker.modalPresentationStyle = .fullScreen
        state = .presentingPicker
        present(picker, animated: false)
    }

    private func showUnavailable(_ message: String) {
        state = .finished
        let unavailable = UnavailableCaptureViewController(message: message, onCancel: onCancel)
        unavailable.modalPresentationStyle = .fullScreen
        present(unavailable, animated: false)
    }

    private func requestAccess(for mediaType: AVMediaType) async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: mediaType) { allowed in
                    continuation.resume(returning: allowed)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}

private final class UnavailableCaptureViewController: UIViewController {
    private let message: String
    private let onCancel: () -> Void

    init(message: String, onCancel: @escaping () -> Void) {
        self.message = message
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton(type: .system)
        button.setTitle("Закрыть", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -22),
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 18),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func close() {
        dismiss(animated: true) { [onCancel] in
            onCancel()
        }
    }
}
