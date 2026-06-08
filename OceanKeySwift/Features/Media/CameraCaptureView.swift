import SwiftUI
import UIKit
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
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return UnavailableCaptureViewController(message: "Камера недоступна", onCancel: onCancel)
        }

        let requestedType = kind == .photo ? UTType.image.identifier : UTType.movie.identifier
        let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera) ?? []
        guard availableTypes.contains(requestedType) else {
            return UnavailableCaptureViewController(message: "Этот режим камеры недоступен", onCancel: onCancel)
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.mediaTypes = [requestedType]
        picker.videoQuality = .typeHigh
        picker.allowsEditing = false
        picker.cameraCaptureMode = kind == .photo ? .photo : .video
        return picker
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
