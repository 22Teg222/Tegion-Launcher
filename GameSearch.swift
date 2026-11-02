import Foundation

/// Library search: exact, partial, category, and approximate (typo-tolerant) matching.
nonisolated enum GameSearch {
    static func results(for rawQuery: String, in games: [Game]) -> [Game] {
        let query = normalize(rawQuery)
        guard !query.isEmpty else { return [] }
        let tokens = query.split(separator: " ").map(String.init)

        return games
            .compactMap { game -> (Game, Int)? in
                let value = score(game, query: query, tokens: tokens)
                return value > 0 ? (game, value) : nil
            }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.title.localizedStandardCompare(rhs.0.title) == .orderedAscending
            }
            .map { $0.0 }
    }

    // MARK: - Scoring

    private static func score(_ game: Game, query: String, tokens: [String]) -> Int {
        let title = normalize(game.title)
        if title == query { return 1000 }

        let titleTokens = title.split(separator: " ").map(String.init)
        var best = 0

        if title.hasPrefix(query) { best = max(best, 900) }
        if titleTokens.contains(where: { $0.hasPrefix(query) }) { best = max(best, 800) }
        if title.contains(query) { best = max(best, 700) }
        if tokens.allSatisfy({ token in titleTokens.contains { $0.hasPrefix(token) } }) {
            best = max(best, 650)
        }

        let compactQuery = query.replacingOccurrences(of: " ", with: "")
        let compactTitle = title.replacingOccurrences(of: " ", with: "")
        if compactQuery.count >= 3, compactTitle.contains(compactQuery) { best = max(best, 600) }

        let category = normalize(game.category.title)
        if category == query || category.contains(query) || query.contains(category) {
            best = max(best, 500)
        }

        let meta = normalize(([game.developer] + game.genres).joined(separator: " "))
        if !meta.isEmpty, meta.contains(query) { best = max(best, 400) }

        if best < 300 {
            if let distance = fuzzyDistance(tokens: tokens, titleTokens: titleTokens) {
                best = max(best, 300 - distance * 40)
            } else if compactQuery.count >= 4 {
                let prefix = String(compactTitle.prefix(compactQuery.count))
                let distance = editDistance(compactQuery, prefix)
                if distance <= max(1, compactQuery.count / 5) {
                    best = max(best, 280 - distance * 40)
                }
            }
        }
        return best
    }

    /// Every query word must be close to some title word (allowing a typo, or a typo in a partial word).
    private static func fuzzyDistance(tokens: [String], titleTokens: [String]) -> Int? {
        var total = 0
        for token in tokens {
            if token.count < 3 {
                guard titleTokens.contains(where: { $0.hasPrefix(token) }) else { return nil }
                continue
            }
            let allowed = token.count <= 4 ? 1 : (token.count <= 7 ? 2 : 3)
            var bestForToken = Int.max
            for titleToken in titleTokens {
                let whole = editDistance(token, titleToken)
                let partial = editDistance(token, String(titleToken.prefix(token.count)))
                bestForToken = min(bestForToken, whole, partial)
            }
            guard bestForToken <= allowed else { return nil }
            total += bestForToken
        }
        return total
    }

    // MARK: - Helpers

    static func normalize(_ text: String) -> String {
        let folded = text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "’", with: "")
        let cleaned = folded.map { $0.isLetter || $0.isNumber ? $0 : Character(" ") }
        return String(cleaned).split(separator: " ").joined(separator: " ")
    }

    static func editDistance(_ lhs: String, _ rhs: String) -> Int {
        let a = Array(lhs)
        let b = Array(rhs)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }

        var previous = Array(0...b.count)
        for i in 1...a.count {
            var current = [Int](repeating: 0, count: b.count + 1)
            current[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
            }
            previous = current
        }
        return previous[b.count]
    }
}
