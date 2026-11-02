import AppKit
import Observation

/// Owns the game library: persistence, artwork files, launching, and drive status.
@MainActor
@Observable
final class LibraryStore {
    private(set) var games: [Game] = []
    /// Set to show an alert (launch failures, save failures).
    var alertMessage: String?
    /// Name of the external drive, as it appears under /Volumes.
    var ssdName = "1TB SSD"

    private var mountTick = 0

    @ObservationIgnored private let folder: URL
    @ObservationIgnored private let artworkFolder: URL
    @ObservationIgnored private let artworkCache = NSCache<NSString, NSImage>()

    private static let ssdKey = "ssdVolumeName"

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        folder = base.appending(path: "Tegion Launcher", directoryHint: .isDirectory)
        artworkFolder = folder.appending(path: "Artwork", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: artworkFolder, withIntermediateDirectories: true)

        if let saved = UserDefaults.standard.string(forKey: Self.ssdKey), !saved.isEmpty {
            ssdName = saved
        }
        load()

        // Re-check the drive whenever any volume is mounted or unmounted.
        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didMountNotification, NSWorkspace.didUnmountNotification] {
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.mountTick += 1 }
            }
        }
    }

    // MARK: - Queries

    func games(in category: GameCategory) -> [Game] {
        games.filter { $0.category == category }
    }

    func game(id: UUID) -> Game? {
        games.first { $0.id == id }
    }

    var isSSDMounted: Bool {
        _ = mountTick
        return FileManager.default.fileExists(atPath: "/Volumes/\(ssdName)")
    }

    func detectLocation(forPath path: String) -> GameLocation {
        path.hasPrefix("/Volumes/\(ssdName)/") ? .ssd : .mac
    }

    func locationName(_ location: GameLocation) -> String {
        switch location {
        case .mac: return "This Mac"
        case .ssd: return ssdName
        }
    }

    // MARK: - Mutations

    /// Adds a new game or updates an existing one. `artwork` is JPEG data to store;
    /// pass `removeArtwork` to clear the current cover.
    func save(_ game: Game, artwork: Data?, removeArtwork: Bool) {
        var game = game

        if let artwork {
            let name = "\(game.id.uuidString)-\(Int(Date().timeIntervalSince1970)).jpg"
            do {
                try artwork.write(to: artworkFolder.appending(path: name), options: .atomic)
                deleteArtwork(named: game.artworkFile)
                game.artworkFile = name
            } catch {
                alertMessage = "Couldn't save the artwork: \(error.localizedDescription)"
            }
        } else if removeArtwork {
            deleteArtwork(named: game.artworkFile)
            game.artworkFile = nil
        }

        if let index = games.firstIndex(where: { $0.id == game.id }) {
            games[index] = game
        } else {
            games.append(game)
        }
        games = Self.sorted(games)
        persist()
    }

    func remove(_ game: Game) {
        deleteArtwork(named: game.artworkFile)
        games.removeAll { $0.id == game.id }
        persist()
    }

    func saveSettings() {
        UserDefaults.standard.set(ssdName, forKey: Self.ssdKey)
    }

    // MARK: - Artwork

    func artwork(for game: Game) -> NSImage? {
        guard let name = game.artworkFile else { return nil }
        if let cached = artworkCache.object(forKey: name as NSString) { return cached }
        guard let image = NSImage(contentsOf: artworkFolder.appending(path: name)) else { return nil }
        artworkCache.setObject(image, forKey: name as NSString)
        return image
    }

    private func deleteArtwork(named name: String?) {
        guard let name else { return }
        try? FileManager.default.removeItem(at: artworkFolder.appending(path: name))
        artworkCache.removeObject(forKey: name as NSString)
    }

    // MARK: - Launching

    func play(_ game: Game) {
        let url = game.appURL

        guard FileManager.default.fileExists(atPath: url.path) else {
            if game.location == .ssd && !isSSDMounted {
                alertMessage = "“\(ssdName)” isn't connected. Connect the drive, then try again."
            } else {
                alertMessage = "Couldn't find “\(game.appName)” at its saved location. Edit the game to choose the app again."
            }
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        let title = game.title
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { [weak self] _, error in
            guard let error else { return }
            Task { @MainActor in
                self?.alertMessage = "Couldn't open “\(title)”: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Persistence

    private var libraryURL: URL { folder.appending(path: "library.json") }

    private func load() {
        guard let data = try? Data(contentsOf: libraryURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Game].self, from: data) {
            games = Self.sorted(decoded)
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            try encoder.encode(games).write(to: libraryURL, options: .atomic)
        } catch {
            alertMessage = "Couldn't save your library: \(error.localizedDescription)"
        }
    }

    private static func sorted(_ games: [Game]) -> [Game] {
        games.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
}
