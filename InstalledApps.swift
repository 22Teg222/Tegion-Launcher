import AppKit

nonisolated struct InstalledApp: Identifiable, Hashable, Sendable {
    let url: URL
    let name: String
    var id: String { url.path }
}

nonisolated enum AppInfo {
    static func displayName(at url: URL) -> String {
        if let bundle = Bundle(url: url) {
            for key in ["CFBundleDisplayName", "CFBundleName"] {
                if let name = bundle.object(forInfoDictionaryKey: key) as? String, !name.isEmpty {
                    return name
                }
            }
        }
        return url.deletingPathExtension().lastPathComponent
    }
}

/// App icons are looked up often (menus, detail view), so keep them cached.
@MainActor
enum AppIcons {
    private static let cache = NSCache<NSString, NSImage>()

    static func image(for path: String, size: CGFloat) -> NSImage {
        let key = "\(path)#\(Int(size))" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let icon = NSWorkspace.shared.icon(forFile: path)
        let copy = (icon.copy() as? NSImage) ?? icon
        copy.size = NSSize(width: size, height: size)
        cache.setObject(copy, forKey: key)
        return copy
    }
}

nonisolated enum InstalledApps {
    /// Finds .app bundles in the usual places plus the external drive. Synchronous on purpose:
    /// call it from a background task.
    static func scan(ssdName: String) -> [InstalledApp] {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser

        var roots: [(url: URL, depth: Int)] = [
            (URL(fileURLWithPath: "/Applications"), 3),
            (URL(fileURLWithPath: "/System/Applications"), 2),
            (home.appending(path: "Applications", directoryHint: .isDirectory), 3)
        ]
        let ssdRoot = URL(fileURLWithPath: "/Volumes/\(ssdName)", isDirectory: true)
        if fileManager.fileExists(atPath: ssdRoot.path) {
            roots.append((ssdRoot, 3))
        }

        var seen = Set<String>()
        var apps: [InstalledApp] = []

        for root in roots {
            guard let enumerator = fileManager.enumerator(
                at: root.url,
                includingPropertiesForKeys: nil,
                options: [.skipsPackageDescendants, .skipsHiddenFiles]
            ) else { continue }

            while let item = enumerator.nextObject() as? URL {
                if item.pathExtension == "app" {
                    if seen.insert(item.path).inserted {
                        apps.append(InstalledApp(url: item, name: AppInfo.displayName(at: item)))
                    }
                } else if enumerator.level >= root.depth {
                    enumerator.skipDescendants()
                }
            }
        }

        return apps.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
