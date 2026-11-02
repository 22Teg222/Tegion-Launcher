import SwiftUI
import AppKit

// MARK: - Glass play button

/// The circular Liquid Glass play button shown when hovering a cover.
struct GlassPlayButton: View {
    var size: CGFloat = 58
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "play.fill")
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(.white)
                .offset(x: size * 0.03)
                .frame(width: size, height: size)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel("Play")
    }
}

// MARK: - Artwork

/// A game's cover, or a quiet placeholder until one is added.
struct ArtworkView: View {
    let game: Game
    @Environment(LibraryStore.self) private var library

    var body: some View {
        if let image = library.artwork(for: game) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.36), Color(white: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack(spacing: 10) {
                Image(nsImage: AppIcons.image(for: game.appPath, size: 44))
                Text(game.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .lineLimit(4)
                    .padding(.horizontal, 12)
            }
        }
    }
}

// MARK: - Game card

struct GameCard: View {
    let game: Game
    var subtitle: String? = nil

    @Environment(LibraryStore.self) private var library
    @Environment(AppState.self) private var app
    @State private var isHovering = false
    /// Cursor position over the cover, -1...1 on each axis. Drives the tilt and the glare.
    @State private var tilt: CGSize = .zero
    @State private var coverSize = CGSize(width: 1, height: 1)

    private let corner: CGFloat = 18
    private let maxTilt = 9.0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            cover

            VStack(alignment: .leading, spacing: 2) {
                Text(game.title)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(isHovering ? .primary : .secondary)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(game.category.color)
                        .lineLimit(1)
                }
            }
        }
        .contentShape(.rect)
        .pointerStyle(.link)
        .onTapGesture { app.open(game) }
        .contextMenu {
            Button("Play", systemImage: "play.fill") { library.play(game) }
            Button("Show App in Finder", systemImage: "magnifyingglass") {
                NSWorkspace.shared.activateFileViewerSelecting([game.appURL])
            }
            Divider()
            Button("Edit…", systemImage: "pencil") { app.editor = .edit(game) }
            Button("Remove from Library", systemImage: "trash", role: .destructive) {
                library.remove(game)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(game.title)
        .accessibilityAddTraits(.isButton)
    }

    /// The cover tilts toward the cursor with a soft highlight, like posters in the Apple TV app.
    /// Hover is tracked on the unrotated wrapper so the tilt never moves the area under the cursor.
    private var cover: some View {
        ZStack {
            Color.clear
                .aspectRatio(2.0 / 3.0, contentMode: .fit)
                .overlay { ArtworkView(game: game) }
                .overlay { hoverLayer }
                .overlay { glare }
                .clipShape(.rect(cornerRadius: corner, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(.white.opacity(0.14), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(isHovering ? 0.4 : 0.22),
                        radius: isHovering ? 18 : 8,
                        x: -tilt.width * 6,
                        y: isHovering ? 10 - tilt.height * 4 : 4)
                .rotation3DEffect(.degrees(tilt.width * maxTilt), axis: (x: 0, y: 1, z: 0), perspective: 0.7)
                .rotation3DEffect(.degrees(-tilt.height * maxTilt), axis: (x: 1, y: 0, z: 0), perspective: 0.7)
                .scaleEffect(isHovering ? 1.05 : 1)
        }
        .contentShape(.rect)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            coverSize = size
        }
        .onContinuousHover { phase in
            switch phase {
            case .active(let point):
                isHovering = true
                tilt = CGSize(
                    width: min(1, max(-1, (point.x / coverSize.width - 0.5) * 2)),
                    height: min(1, max(-1, (point.y / coverSize.height - 0.5) * 2))
                )
            case .ended:
                isHovering = false
                tilt = .zero
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.2), value: tilt)
        .animation(.spring(duration: 0.3, bounce: 0.2), value: isHovering)
    }

    @ViewBuilder
    private var hoverLayer: some View {
        if isHovering {
            ZStack {
                Color.black.opacity(0.18)
                GlassPlayButton { library.play(game) }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }
    }

    /// A soft light that follows the cursor across the cover.
    private var glare: some View {
        RadialGradient(
            colors: [.white.opacity(0.28), .clear],
            center: UnitPoint(x: (tilt.width + 1) / 2, y: (tilt.height + 1) / 2),
            startRadius: 0,
            endRadius: 150
        )
        .blendMode(.plusLighter)
        .opacity(isHovering ? 1 : 0)
        .allowsHitTesting(false)
    }
}

// MARK: - Grid

struct GameGrid: View {
    let games: [Game]
    var showsCategory = false

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 24, alignment: .top)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 28) {
            ForEach(games) { game in
                GameCard(game: game, subtitle: showsCategory ? game.category.title : nil)
            }
        }
    }
}
