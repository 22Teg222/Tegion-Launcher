import SwiftUI

struct HomeView: View {
    @Environment(LibraryStore.self) private var library

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 40) {
                ForEach(GameCategory.allCases) { category in
                    CategorySection(category: category, games: library.games(in: category))
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
    }
}

struct CategorySection: View {
    let category: GameCategory
    let games: [Game]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(category.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(category.color)
                Rectangle()
                    .fill(category.color.opacity(0.45))
                    .frame(height: 1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            if games.isEmpty {
                Text("No games yet")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            } else {
                GameGrid(games: games)
            }
        }
    }
}
