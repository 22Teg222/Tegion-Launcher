import SwiftUI

struct RootView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(AppState.self) private var app

    var body: some View {
        @Bindable var app = app

        NavigationStack(path: $app.path) {
            Group {
                switch app.page {
                case .home:
                    HomeView()
                        .transition(.opacity)
                case .search:
                    SearchView()
                        .transition(.opacity)
                }
            }
            .animation(.smooth(duration: 0.25), value: app.page)
            .navigationTitle(app.page.title)
            .navigationSubtitle(app.page == .home ? gameCountText : "")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Page", selection: $app.page) {
                        ForEach(AppState.Page.allCases) { page in
                            Label(page.title, systemImage: page.symbol).tag(page)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 190)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        app.editor = .add
                    } label: {
                        Label("Add Game", systemImage: "plus")
                    }
                    .help("Add Game")
                    .pointerStyle(.link)
                }
            }
            .navigationDestination(for: UUID.self) { id in
                GameDetailView(gameID: id)
            }
        }
        .sheet(item: $app.editor) { mode in
            AddGameView(editing: mode.game)
        }
        .alert(
            "Couldn't Open Game",
            isPresented: Binding(
                get: { library.alertMessage != nil },
                set: { if !$0 { library.alertMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(library.alertMessage ?? "")
        }
    }

    private var gameCountText: String {
        let count = library.games.count
        return count == 1 ? "1 game" : "\(count) games"
    }
}
