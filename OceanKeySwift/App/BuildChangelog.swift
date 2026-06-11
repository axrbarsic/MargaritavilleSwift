import Foundation

struct BuildChangelogEntry: Identifiable, Equatable {
    let id = UUID()
    let version: String
    let date: String
    let changes: [String]
}

enum BuildChangelog {
    static let entries = recentEntries + midEntries + archiveEntries + legacyEntries
}
