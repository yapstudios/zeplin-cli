import Foundation

public enum Paths {

    // MARK: - Config

    public static var configDirectory: URL {
        let base: URL
        if let xdg = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"], !xdg.isEmpty {
            base = URL(fileURLWithPath: xdg)
        } else {
            base = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config")
        }
        return base.appendingPathComponent("zeplin-cli")
    }

    public static var globalConfigFile: URL {
        configDirectory.appendingPathComponent("config.json")
    }

    public static var globalConfigPath: String {
        if let xdg = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"], !xdg.isEmpty {
            return URL(fileURLWithPath: xdg)
                .appendingPathComponent("zeplin-cli/config.json").path
        }
        return "~/.config/zeplin-cli/config.json"
    }

    // MARK: - Cache

    public static var cacheDirectory: URL {
        let base: URL
        if let xdg = ProcessInfo.processInfo.environment["XDG_CACHE_HOME"], !xdg.isEmpty {
            base = URL(fileURLWithPath: xdg)
        } else {
            base = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".cache")
        }
        return base.appendingPathComponent("zeplin-cli")
    }

    public static var updateCheckCacheFile: URL {
        cacheDirectory.appendingPathComponent("update-check.json")
    }

    // MARK: - Local (project-scoped)

    public static let localConfigPath = ".zeplin-cli/config.json"
}
