import Foundation

/// Where a game's files live.
nonisolated enum GameLocation: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case mac
    case ssd

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .mac: return "laptopcomputer"
        case .ssd: return "externaldrive.fill"
        }
    }
}

nonisolated struct Game: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var title: String
    var category: GameCategory
    /// Absolute path of the .app that launches this game.
    var appPath: String
    var location: GameLocation
    /// File name inside the Artwork folder.
    var artworkFile: String?
    var summary = ""
    var developer = ""
    var releaseYear: Int?
    var genres: [String] = []
    var igdbID: Int?
    var dateAdded = Date()

    var appURL: URL { URL(fileURLWithPath: appPath) }
    var appName: String { AppInfo.displayName(at: appURL) }
}
