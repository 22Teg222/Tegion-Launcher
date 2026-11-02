import Foundation

/// The shelves shown on the Home page, in display order.
nonisolated enum GameCategory: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case nativeMac = "Native Mac"
    case windows = "Windows"
    case mobile = "Mobile"
    case nintendo = "Nintendo"
    case nativeNintendo = "Native Nintendo"
    case xbox = "Xbox"
    case playStation = "PlayStation"

    var id: String { rawValue }
    var title: String { rawValue }
}
