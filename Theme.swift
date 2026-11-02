import SwiftUI

extension GameCategory {
    /// System colour used for the shelf's title and divider, so it adapts to light and dark mode.
    var color: Color {
        switch self {
        case .nativeMac: return .purple
        case .windows: return .cyan
        case .mobile: return .pink
        case .nintendo: return .red
        case .nativeNintendo: return .orange
        case .xbox: return .green
        case .playStation: return .blue
        }
    }
}
