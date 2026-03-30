import Foundation
import ZeplinKit

public enum UpdateChecker {

    static let currentVersion = Zeplin.configuration.version

    private static let repoTagsURL = "https://api.github.com/repos/yapstudios/zeplin-cli/tags"
    private static let cacheFreshness: TimeInterval = 86400 // 24 hours
    private static let fetchTimeout: TimeInterval = 3

    private static var cacheURL: URL {
        Paths.updateCheckCacheFile
    }

    public struct Cache: Codable {
        public var lastCheck: TimeInterval
        public var latestVersion: String
        public var ignoredVersion: String?
    }

    // MARK: - Public

    public static func checkAndNotify() {
        let cache = readCache()
        let now = Date().timeIntervalSince1970

        if let cache, now - cache.lastCheck < cacheFreshness {
            printNoticeIfNeeded(latest: cache.latestVersion, ignored: cache.ignoredVersion)
            return
        }

        guard let latest = fetchLatestVersion() else { return }

        let newCache = Cache(
            lastCheck: now,
            latestVersion: latest,
            ignoredVersion: cache?.ignoredVersion
        )
        writeCache(newCache)
        printNoticeIfNeeded(latest: latest, ignored: cache?.ignoredVersion)
    }

    static func forceCheck() -> String {
        guard let latest = fetchLatestVersion() else {
            return "Could not check for updates."
        }

        let cache = readCache()
        let newCache = Cache(
            lastCheck: Date().timeIntervalSince1970,
            latestVersion: latest,
            ignoredVersion: cache?.ignoredVersion
        )
        writeCache(newCache)

        if isNewer(latest, than: currentVersion) {
            return formatNotice(current: currentVersion, latest: latest)
        }
        return "Up to date (\(currentVersion))"
    }

    static func ignoreLatest() -> String {
        var cache = readCache() ?? Cache(
            lastCheck: Date().timeIntervalSince1970,
            latestVersion: currentVersion,
            ignoredVersion: nil
        )

        if let latest = fetchLatestVersion() {
            cache.latestVersion = latest
            cache.lastCheck = Date().timeIntervalSince1970
        }

        cache.ignoredVersion = cache.latestVersion
        writeCache(cache)
        return "Ignoring version \(cache.latestVersion). You won't be notified until a newer version is released."
    }

    // MARK: - Version comparison

    public static func isNewer(_ a: String, than b: String) -> Bool {
        let partsA = a.split(separator: ".").compactMap { Int($0) }
        let partsB = b.split(separator: ".").compactMap { Int($0) }
        let count = max(partsA.count, partsB.count)
        for i in 0..<count {
            let va = i < partsA.count ? partsA[i] : 0
            let vb = i < partsB.count ? partsB[i] : 0
            if va > vb { return true }
            if va < vb { return false }
        }
        return false
    }

    // MARK: - Network

    static func fetchLatestVersion() -> String? {
        guard let url = URL(string: repoTagsURL) else { return nil }
        var request = URLRequest(url: url, timeoutInterval: fetchTimeout)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let semaphore = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var result: String?

        let task = URLSession.shared.dataTask(with: request) { data, _, _ in
            defer { semaphore.signal() }
            guard let data,
                  let tags = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let first = tags.first,
                  let name = first["name"] as? String else { return }
            result = name.hasPrefix("v") ? String(name.dropFirst()) : name
        }
        task.resume()
        semaphore.wait()
        return result
    }

    // MARK: - Cache I/O

    private static func readCache() -> Cache? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONDecoder().decode(Cache.self, from: data)
    }

    private static func writeCache(_ cache: Cache) {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        let dir = cacheURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: cacheURL, options: .atomic)
    }

    // MARK: - Output

    private static func printNoticeIfNeeded(latest: String, ignored: String?) {
        guard isNewer(latest, than: currentVersion) else { return }
        if let ignored, ignored == latest { return }
        FileHandle.standardError.write(Data(formatNotice(current: currentVersion, latest: latest).utf8))
        FileHandle.standardError.write(Data("\n".utf8))
    }

    private static func formatNotice(current: String, latest: String) -> String {
        """
        Update available: \(current) → \(latest)
          brew update && brew upgrade zeplin-cli
          mint install yapstudios/zeplin-cli
          Run 'zeplin-cli check-for-update --ignore' to dismiss.
        """
    }
}
