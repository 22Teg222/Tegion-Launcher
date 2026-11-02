import AppKit

nonisolated enum ImageTools {
    /// Re-encodes any image NSImage can read as JPEG so every stored cover is the same format.
    static func jpegData(from data: Data, quality: Double = 0.92) -> Data? {
        guard
            let image = NSImage(data: data),
            let tiff = image.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiff)
        else { return nil }
        return rep.representation(using: .jpeg, properties: [.compressionFactor: quality])
    }
}

nonisolated enum ImageDownloader {
    static func download(_ url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
