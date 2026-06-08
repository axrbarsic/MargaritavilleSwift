import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

struct BackgroundVideoPickerLabel: View {
    let videoStatus: String

    var body: some View {
        SettingsInfoRow(
            title: "Видео",
            value: videoStatus,
            systemName: "film.fill"
        )
    }
}

struct PickedBackgroundVideo: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let copyURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension)
            if FileManager.default.fileExists(atPath: copyURL.path) {
                try FileManager.default.removeItem(at: copyURL)
            }
            try FileManager.default.copyItem(at: received.file, to: copyURL)
            return PickedBackgroundVideo(url: copyURL)
        }
    }
}
