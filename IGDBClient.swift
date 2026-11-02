import Foundation

nonisolated struct IGDBGame: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let summary: String
    let developer: String
    let year: Int?
    let genres: [String]
    let coverURL: URL?
    let thumbnailURL: URL?
}

nonisolated enum IGDBError: LocalizedError {
    case missingCredentials
    case authentication
    case server(Int)

    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "Add your IGDB Client ID and Secret in Settings to search for games."
        case .authentication:
            return "IGDB rejected the credentials. Check the Client ID and Secret in Settings."
        case .server(let code):
            return "IGDB returned an error (\(code))."
        }
    }
}

// MARK: - Wire formats

private nonisolated struct IGDBRawGame: Decodable {
    struct Named: Decodable { let name: String? }
    struct Cover: Decodable { let image_id: String? }
    struct Involved: Decodable {
        let developer: Bool?
        let company: Named?
    }

    let id: Int
    let name: String
    let summary: String?
    let first_release_date: Double?
    let genres: [Named]?
    let cover: Cover?
    let involved_companies: [Involved]?
}

private nonisolated struct TwitchToken: Decodable {
    let access_token: String
    let expires_in: Double
}

// MARK: - Client

/// Talks to IGDB (https://api-docs.igdb.com). Credentials come from a free Twitch developer app
/// and are stored via Settings.
actor IGDBClient {
    static let shared = IGDBClient()

    private var token: String?
    private var tokenOwner: String?
    private var tokenExpiry = Date.distantPast

    func search(_ query: String) async throws -> [IGDBGame] {
        let clientID = (UserDefaults.standard.string(forKey: "igdbClientID") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let secret = (UserDefaults.standard.string(forKey: "igdbClientSecret") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clientID.isEmpty, !secret.isEmpty else { throw IGDBError.missingCredentials }

        do {
            return try await performSearch(query, clientID: clientID, secret: secret)
        } catch IGDBError.authentication {
            // The cached token may have been revoked; get a fresh one once.
            token = nil
            return try await performSearch(query, clientID: clientID, secret: secret)
        }
    }

    private func performSearch(_ query: String, clientID: String, secret: String) async throws -> [IGDBGame] {
        let accessToken = try await validToken(clientID: clientID, secret: secret)

        var request = URLRequest(url: URL(string: "https://api.igdb.com/v4/games")!)
        request.httpMethod = "POST"
        request.setValue(clientID, forHTTPHeaderField: "Client-ID")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let escaped = query
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let body = """
        search "\(escaped)"; fields name,summary,first_release_date,genres.name,cover.image_id,involved_companies.developer,involved_companies.company.name; where version_parent = null; limit 12;
        """
        request.httpBody = Data(body.utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw IGDBError.server(0) }
        if http.statusCode == 401 { throw IGDBError.authentication }
        guard http.statusCode == 200 else { throw IGDBError.server(http.statusCode) }

        let raw = try JSONDecoder().decode([IGDBRawGame].self, from: data)
        return raw.map { Self.convert($0) }
    }

    private func validToken(clientID: String, secret: String) async throws -> String {
        if let token, tokenOwner == clientID, tokenExpiry > Date() { return token }

        var components = URLComponents(string: "https://id.twitch.tv/oauth2/token")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "client_secret", value: secret),
            URLQueryItem(name: "grant_type", value: "client_credentials")
        ]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw IGDBError.server(0) }
        if (400...403).contains(http.statusCode) { throw IGDBError.authentication }
        guard http.statusCode == 200 else { throw IGDBError.server(http.statusCode) }

        let decoded = try JSONDecoder().decode(TwitchToken.self, from: data)
        token = decoded.access_token
        tokenOwner = clientID
        tokenExpiry = Date().addingTimeInterval(max(60, decoded.expires_in - 300))
        return decoded.access_token
    }

    private static func convert(_ raw: IGDBRawGame) -> IGDBGame {
        var year: Int?
        if let timestamp = raw.first_release_date, let utc = TimeZone(identifier: "UTC") {
            year = Calendar(identifier: .gregorian)
                .dateComponents(in: utc, from: Date(timeIntervalSince1970: timestamp)).year
        }

        let companies = raw.involved_companies ?? []
        let developer = companies.first(where: { $0.developer == true })?.company?.name
            ?? companies.first?.company?.name
            ?? ""

        let base = "https://images.igdb.com/igdb/image/upload"
        let imageID = raw.cover?.image_id

        return IGDBGame(
            id: raw.id,
            name: raw.name,
            summary: raw.summary ?? "",
            developer: developer,
            year: year,
            genres: (raw.genres ?? []).compactMap { $0.name },
            coverURL: imageID.flatMap { URL(string: "\(base)/t_cover_big_2x/\($0).jpg") },
            thumbnailURL: imageID.flatMap { URL(string: "\(base)/t_cover_small/\($0).jpg") }
        )
    }
}
