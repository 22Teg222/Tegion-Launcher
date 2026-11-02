import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AddGameView: View {
    private let existing: Game?

    @Environment(LibraryStore.self) private var library
    @Environment(\.dismiss) private var dismiss
    @AppStorage("igdbClientID") private var clientID = ""
    @AppStorage("igdbClientSecret") private var clientSecret = ""

    // Search
    @State private var query = ""
    @State private var results: [IGDBGame] = []
    @State private var selectedCandidate: Int?
    @State private var isSearching = false
    @State private var searchError: String?

    // Editable fields
    @State private var title: String
    @State private var category: GameCategory
    @State private var selectedAppPath: String
    @State private var location: GameLocation
    @State private var locationEdited: Bool
    @State private var summary: String
    @State private var developer: String
    @State private var yearText: String
    @State private var genresText: String
    @State private var igdbID: Int?

    // Artwork
    @State private var artworkImage: NSImage?
    @State private var artworkData: Data?
    @State private var artworkRemoved = false
    @State private var isLoadingArtwork = false

    // Installed apps
    @State private var apps: [InstalledApp] = []
    @State private var isLoadingApps = true

    init(editing game: Game? = nil) {
        existing = game
        _title = State(initialValue: game?.title ?? "")
        _category = State(initialValue: game?.category ?? .nativeMac)
        _selectedAppPath = State(initialValue: game?.appPath ?? "")
        _location = State(initialValue: game?.location ?? .mac)
        _locationEdited = State(initialValue: game != nil)
        _summary = State(initialValue: game?.summary ?? "")
        _developer = State(initialValue: game?.developer ?? "")
        _yearText = State(initialValue: game?.releaseYear.map(String.init) ?? "")
        _genresText = State(initialValue: game?.genres.joined(separator: ", ") ?? "")
        _igdbID = State(initialValue: game?.igdbID)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            searchStatus
            candidateStrip
            form
            footer
        }
        .frame(width: 680, height: 760)
        .task { await loadApps() }
        .task(id: query) { await runSearch() }
        .onAppear {
            if let existing, artworkImage == nil {
                artworkImage = library.artwork(for: existing)
            }
        }
        .onChange(of: selectedAppPath) { _, newPath in
            if !locationEdited, !newPath.isEmpty {
                location = library.detectLocation(forPath: newPath)
            }
        }
    }

    // MARK: - Header & search

    private var header: some View {
        HStack {
            Text(existing == nil ? "Add Game" : "Edit Game")
                .font(.title2.weight(.semibold))
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 14)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search for a game to fill in details", text: $query)
                .textFieldStyle(.plain)
            if isSearching {
                ProgressView().controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var searchStatus: some View {
        if !hasCredentials {
            HStack(spacing: 6) {
                Image(systemName: "key.fill")
                Text("Add your IGDB credentials to search automatically.")
                SettingsLink { Text("Open Settings") }
                    .buttonStyle(.link)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 28)
            .padding(.top, 8)
        } else if let searchError {
            Label(searchError, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(.orange)
                .padding(.horizontal, 28)
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var candidateStrip: some View {
        if !results.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(results) { candidate in
                        CandidateButton(
                            candidate: candidate,
                            isSelected: selectedCandidate == candidate.id
                        ) {
                            apply(candidate)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Form

    private var form: some View {
        Form {
            Section("Game") {
                LabeledContent("Artwork") {
                    HStack(spacing: 12) {
                        artworkPreview
                        VStack(alignment: .trailing, spacing: 6) {
                            Button("Choose Image…", action: chooseImage)
                            if artworkImage != nil {
                                Button("Remove", role: .destructive, action: removeArtwork)
                            }
                        }
                    }
                }

                TextField("Title", text: $title)

                Picker("Category", selection: $category) {
                    ForEach(GameCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
            }

            Section("Launch") {
                LabeledContent("Application") {
                    HStack(spacing: 8) {
                        if isLoadingApps { ProgressView().controlSize(.small) }
                        AppPicker(apps: pickerApps, selection: selectedAppPath) { selectedAppPath = $0 }
                            .equatable()
                        Button("Browse…", action: chooseApp)
                    }
                }

                Picker("Location", selection: locationBinding) {
                    Text("This Mac").tag(GameLocation.mac)
                    Text(library.ssdName).tag(GameLocation.ssd)
                }
                .pickerStyle(.segmented)

                if location == .ssd && !library.isSSDMounted {
                    Label("\(library.ssdName) isn't connected right now.",
                          systemImage: "externaldrive.badge.exclamationmark")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

    private var artworkPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.quaternary)
            if let artworkImage {
                Image(nsImage: artworkImage)
                    .resizable()
                    .scaledToFill()
            } else if isLoadingArtwork {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 52, height: 78)
        .clipShape(.rect(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 0.5)
        }
    }

    private var footer: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.glass)
                Button(existing == nil ? "Add Game" : "Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.glassProminent)
                    .disabled(!canSave)
            }
        }
        .controlSize(.large)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Derived state

    private var hasCredentials: Bool {
        !clientID.trimmingCharacters(in: .whitespaces).isEmpty
            && !clientSecret.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedAppPath.isEmpty
    }

    /// Installed apps plus the currently chosen app if it lives somewhere we didn't scan.
    private var pickerApps: [InstalledApp] {
        var list = apps
        if !selectedAppPath.isEmpty, !list.contains(where: { $0.id == selectedAppPath }) {
            let url = URL(fileURLWithPath: selectedAppPath)
            list.insert(InstalledApp(url: url, name: AppInfo.displayName(at: url)), at: 0)
        }
        return list
    }

    private var locationBinding: Binding<GameLocation> {
        Binding(
            get: { location },
            set: {
                location = $0
                locationEdited = true
            }
        )
    }

    // MARK: - Actions

    private func loadApps() async {
        let ssd = library.ssdName
        let found = await Task.detached(priority: .userInitiated) {
            InstalledApps.scan(ssdName: ssd)
        }.value
        apps = found
        isLoadingApps = false
    }

    private func runSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2, hasCredentials else {
            results = []
            isSearching = false
            searchError = nil
            return
        }

        // Debounce: wait for a pause in typing.
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }

        isSearching = true
        do {
            let found = try await IGDBClient.shared.search(trimmed)
            guard !Task.isCancelled else { return }
            results = found
            searchError = nil
        } catch {
            guard !Task.isCancelled else { return }
            results = []
            searchError = error.localizedDescription
        }
        isSearching = false
    }

    private func apply(_ candidate: IGDBGame) {
        selectedCandidate = candidate.id
        igdbID = candidate.id
        title = candidate.name
        summary = candidate.summary
        developer = candidate.developer
        yearText = candidate.year.map(String.init) ?? ""
        genresText = candidate.genres.joined(separator: ", ")

        if let url = candidate.coverURL {
            Task { await loadArtwork(from: url) }
        }
    }

    private func loadArtwork(from url: URL) async {
        isLoadingArtwork = true
        defer { isLoadingArtwork = false }
        guard
            let data = try? await ImageDownloader.download(url),
            let jpeg = ImageTools.jpegData(from: data)
        else { return }
        artworkData = jpeg
        artworkImage = NSImage(data: jpeg)
        artworkRemoved = false
    }

    private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        guard
            panel.runModal() == .OK,
            let url = panel.url,
            let data = try? Data(contentsOf: url),
            let jpeg = ImageTools.jpegData(from: data)
        else { return }
        artworkData = jpeg
        artworkImage = NSImage(data: jpeg)
        artworkRemoved = false
    }

    private func removeArtwork() {
        artworkData = nil
        artworkImage = nil
        artworkRemoved = true
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        if panel.runModal() == .OK, let url = panel.url {
            selectedAppPath = url.path
        }
    }

    private func save() {
        var game = existing ?? Game(
            title: "",
            category: category,
            appPath: selectedAppPath,
            location: location
        )
        game.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        game.category = category
        game.appPath = selectedAppPath
        game.location = location
        game.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        game.developer = developer.trimmingCharacters(in: .whitespacesAndNewlines)
        game.releaseYear = Int(yearText.trimmingCharacters(in: .whitespaces))
        game.genres = genresText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        game.igdbID = igdbID

        library.save(game, artwork: artworkData, removeArtwork: artworkRemoved)
        dismiss()
    }
}

// MARK: - Pieces

/// One IGDB search result: cover thumbnail, name, year.
private struct CandidateButton: View {
    let candidate: IGDBGame
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                AsyncImage(url: candidate.thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Rectangle().fill(.quaternary)
                    }
                }
                .frame(width: 72, height: 102)
                .clipShape(.rect(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(isSelected ? Color.accentColor : .white.opacity(0.14),
                                      lineWidth: isSelected ? 3 : 0.5)
                }

                Text(candidate.name)
                    .font(.caption.weight(.medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(width: 72, alignment: .leading)

                if let year = candidate.year {
                    Text(String(year))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(candidate.name)
    }
}

/// The application dropdown. Equatable so typing in other fields doesn't rebuild a menu of hundreds of apps.
private struct AppPicker: View, Equatable {
    let apps: [InstalledApp]
    let selection: String
    let onSelect: (String) -> Void

    nonisolated static func == (lhs: AppPicker, rhs: AppPicker) -> Bool {
        lhs.apps == rhs.apps && lhs.selection == rhs.selection
    }

    var body: some View {
        Picker("Application", selection: Binding(get: { selection }, set: { onSelect($0) })) {
            if selection.isEmpty {
                Text("Choose an App…").tag("")
            }
            ForEach(apps) { app in
                Label {
                    Text(app.name)
                } icon: {
                    Image(nsImage: AppIcons.image(for: app.url.path, size: 16))
                }
                .tag(app.id)
            }
        }
        .labelsHidden()
    }
}
