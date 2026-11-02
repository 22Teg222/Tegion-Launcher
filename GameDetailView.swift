import SwiftUI

struct GameDetailView: View {
    let gameID: UUID

    @Environment(LibraryStore.self) private var library
    @Environment(AppState.self) private var app
    @State private var confirmRemove = false

    var body: some View {
        if let game = library.game(id: gameID) {
            content(for: game)
        } else {
            ContentUnavailableView("Game Not Found", systemImage: "questionmark.square.dashed")
        }
    }

    private func content(for game: Game) -> some View {
        HStack(alignment: .center, spacing: 48) {
            Color.clear
                .aspectRatio(2.0 / 3.0, contentMode: .fit)
                .frame(width: 300)
                .overlay { ArtworkView(game: game) }
                .clipShape(.rect(cornerRadius: 26, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(.white.opacity(0.16), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.35), radius: 30, y: 16)

            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(game.category.title.uppercased())
                        .font(.caption.weight(.semibold))
                        .tracking(0.8)
                        .foregroundStyle(game.category.color)
                    Text(game.title)
                        .font(.system(size: 36, weight: .bold))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 0) {
                    InfoRow(label: "Application") {
                        HStack(spacing: 10) {
                            Image(nsImage: AppIcons.image(for: game.appPath, size: 28))
                            Text(game.appName)
                        }
                    }
                    Divider().padding(.vertical, 12)
                    InfoRow(label: "Location") {
                        HStack(spacing: 8) {
                            Image(systemName: game.location.symbol)
                                .foregroundStyle(.secondary)
                            Text(library.locationName(game.location))
                            if game.location == .ssd && !library.isSSDMounted {
                                Text("Not connected")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
                .padding(20)
                .glassEffect(.regular, in: .rect(cornerRadius: 24, style: .continuous))

                Button {
                    library.play(game)
                } label: {
                    Label("Play", systemImage: "play.fill")
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.extraLarge)
                .tint(.green)
                .keyboardShortcut(.defaultAction)
                .pointerStyle(.link)
            }
            .frame(minWidth: 280, maxWidth: 420, alignment: .leading)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { backdrop(for: game) }
        .navigationTitle(game.title)
        .toolbar {
            ToolbarItemGroup {
                Button("Edit", systemImage: "pencil") { app.editor = .edit(game) }
                Button("Remove", systemImage: "trash") { confirmRemove = true }
            }
        }
        .confirmationDialog(
            "Remove “\(game.title)” from your library?",
            isPresented: $confirmRemove,
            titleVisibility: .visible
        ) {
            Button("Remove from Library", role: .destructive) {
                library.remove(game)
                app.path.removeAll()
            }
        } message: {
            Text("The game's app isn't deleted from your Mac.")
        }
    }

    /// A soft, blurred wash of the cover behind the page.
    @ViewBuilder
    private func backdrop(for game: Game) -> some View {
        if let image = library.artwork(for: game) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .blur(radius: 90)
                .saturation(1.2)
                .opacity(0.4)
                .ignoresSafeArea()
        }
    }
}

private struct InfoRow<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content
                .font(.title3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
