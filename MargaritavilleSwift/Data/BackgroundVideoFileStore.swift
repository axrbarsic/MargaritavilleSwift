import Foundation

struct BackgroundVideoFileStore {
    private let rootDirectory: URL
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        rootDirectory = AppStorageDirectory.applicationSupportSubdirectory(fileManager: fileManager)
    }

    func saveVideo(from sourceURL: URL) throws -> String {
        let relativePath = "Background/video-wallpaper.mov"
        let destinationURL = rootDirectory.appendingPathComponent(relativePath)
        try fileManager.createDirectory(
            at: destinationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        return relativePath
    }

    func url(for relativePath: String) -> URL {
        rootDirectory.appendingPathComponent(relativePath)
    }
}
