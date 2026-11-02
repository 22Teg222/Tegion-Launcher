import SwiftUI
import Observation

/// What the Add Game sheet is doing.
enum EditorMode: Identifiable {
    case add
    case edit(Game)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let game): return game.id.uuidString
        }
    }

    var game: Game? {
        switch self {
        case .add: return nil
        case .edit(let game): return game
        }
    }
}

/// UI state shared across the window: current page, navigation, sheets.
@MainActor
@Observable
final class AppState {
    enum Page: String, CaseIterable, Identifiable {
        case home
        case search

        var id: String { rawValue }

        var title: String {
            switch self {
            case .home: return "Home"
            case .search: return "Search"
            }
        }

        var symbol: String {
            switch self {
            case .home: return "house"
            case .search: return "magnifyingglass"
            }
        }
    }

    var page: Page = .home
    /// Game IDs pushed onto the navigation stack (details view).
    var path: [UUID] = []
    var editor: EditorMode?
    var searchText = ""

    func open(_ game: Game) {
        path.append(game.id)
    }
}
