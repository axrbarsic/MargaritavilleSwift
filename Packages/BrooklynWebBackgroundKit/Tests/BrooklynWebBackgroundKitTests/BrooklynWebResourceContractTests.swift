import CryptoKit
import Foundation
import Testing
@testable import BrooklynWebBackgroundKit

@Test func webDistributionIsOfflineAndCanvasOnly() throws {
    let root = try BrooklynWebResources.distributionDirectory()
    let rootNames = try Set(
        FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: nil
        ).map(\.lastPathComponent)
    )
    #expect(rootNames == [
        "assets",
        "index.html",
        "potsdamer_platz_1k.hdr",
        "tex0.png",
        "tex1.png"
    ])

    let index = try String(
        contentsOf: root.appendingPathComponent("index.html"),
        encoding: .utf8
    )
    #expect(index.contains("Content-Security-Policy"))
    #expect(index.contains("<script defer src=\"./assets/brooklyn.js\"></script>"))
    #expect(!index.contains("type=\"module\""))
    #expect(!index.contains("crossorigin"))
    #expect(!index.contains("<link"))
    #expect(!index.contains("http://"))
    #expect(!index.contains("https://"))

    let assetNames = try Set(
        FileManager.default.contentsOfDirectory(
            at: root.appendingPathComponent("assets", isDirectory: true),
            includingPropertiesForKeys: nil
        ).map(\.lastPathComponent)
    )
    #expect(assetNames == ["brooklyn.js"])

    let text = try distributionText(root: root)
    for forbidden in [
        "cdn.segment.com",
        "window.open",
        "mailto:",
        "resume.pdf",
        "tex2.png",
        "Code Opacity",
        "I am a full stack",
        "brooklyn.bb.nicholson",
        "imbabybrooklyn",
        "raw.githack.com"
    ] {
        #expect(!text.contains(forbidden))
    }
    #expect(text.contains("__brooklynSetActive"))
    #expect(text.contains("__brooklynSetAppearance"))
    #expect(text.contains("__brooklynSetHighRefresh"))
    #expect(text.contains("__brooklynStartTelemetry"))
    #expect(text.contains("brooklynTelemetry"))
    #expect(text.contains("manualAdvanceEffectiveCadenceHz"))
    #expect(text.contains("presentationMeasured"))
    #expect(text.contains("sceneInstanceCount"))
    #expect(text.contains("transformMotionCadenceHz"))
    #expect(text.contains("data:image/png;base64,"))
    #expect(!text.contains("window.location.href"))
}

@Test func runtimeAssetsMatchPinnedHashes() throws {
    let root = try BrooklynWebResources.distributionDirectory()
    #expect(try sha256(root.appendingPathComponent("tex0.png")) ==
        "8eeecc01de0196b20eb3c74038eac28ccf58c63edd88b8c4db35c10023516ad2")
    #expect(try sha256(root.appendingPathComponent("tex1.png")) ==
        "7a99f66974d77abed24f12bce7553b6295f9fc03b11405baefa21724d962184e")
    #expect(try sha256(root.appendingPathComponent("potsdamer_platz_1k.hdr")) ==
        "7afe4c2f9700ee78c7477c53fa355463d7dda1fdede401432d6b5f9ff0a95696")
}

private func distributionText(root: URL) throws -> String {
    let enumerator = try #require(
        FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil
        )
    )
    var text = ""
    for case let file as URL in enumerator {
        guard ["html", "js", "css"].contains(file.pathExtension) else { continue }
        text += try String(contentsOf: file, encoding: .utf8)
    }
    return text
}

private func sha256(_ url: URL) throws -> String {
    SHA256.hash(data: try Data(contentsOf: url))
        .map { String(format: "%02x", $0) }
        .joined()
}
