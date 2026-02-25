import Foundation

public struct CredentialOptions: Sendable {
    public var token: String?
    public var organizationId: String?
    public var profile: String?

    public init(token: String? = nil, organizationId: String? = nil, profile: String? = nil) {
        self.token = token
        self.organizationId = organizationId
        self.profile = profile
    }
}

public struct CredentialResolver: Sendable {
    public static let globalConfigPath = "~/.zeplin/config.json"
    public static let localConfigPath = ".zeplin/config.json"

    public static let envToken = "ZEPLIN_TOKEN"
    public static let envOrganizationId = "ZEPLIN_ORGANIZATION_ID"

    public init() {}

    public func resolve(options: CredentialOptions = CredentialOptions()) throws -> Credentials {
        if let creds = resolveFromOptions(options) {
            return creds
        }

        if let creds = resolveFromEnvironment() {
            return creds
        }

        let profileName = options.profile

        if let creds = try resolveFromConfig(Self.localConfigPath, profileName: profileName) {
            return creds
        }

        if let creds = try resolveFromConfig(Self.globalConfigPath, profileName: profileName) {
            return creds
        }

        throw CLIError.missingCredentials(
            """
            No credentials configured.

            Run 'zeplin-cli auth init' to set up credentials interactively.

            Credentials can also be provided via:
              - Command-line flag (--token)
              - Environment variable (ZEPLIN_TOKEN)
              - Config file (~/.zeplin/config.json)

            Get a personal access token at:
              https://app.zeplin.io/profile/developer
            """
        )
    }

    private func resolveFromOptions(_ options: CredentialOptions) -> Credentials? {
        guard let token = options.token else { return nil }
        return Credentials(token: token, organizationId: options.organizationId)
    }

    private func resolveFromEnvironment() -> Credentials? {
        guard let token = ProcessInfo.processInfo.environment[Self.envToken] else { return nil }
        let orgId = ProcessInfo.processInfo.environment[Self.envOrganizationId]
        return Credentials(token: token, organizationId: orgId)
    }

    private func resolveFromConfig(_ path: String, profileName: String?) throws -> Credentials? {
        let expandedPath = (path as NSString).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expandedPath) else {
            return nil
        }

        let data: Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: expandedPath))
        } catch {
            throw CLIError.configFileError("Could not read \(path): \(error.localizedDescription)")
        }

        let config: ConfigFile
        do {
            config = try JSONDecoder().decode(ConfigFile.self, from: data)
        } catch {
            throw CLIError.configFileError("Invalid JSON in \(path): \(error.localizedDescription)")
        }

        let targetProfile = profileName ?? config.defaultProfile
        guard let name = targetProfile, let profile = config.profiles[name] else {
            if profileName != nil {
                throw CLIError.configFileError("Profile '\(profileName!)' not found in \(path)")
            }
            return nil
        }

        return profile.toCredentials()
    }

    public func loadConfig(from path: String) throws -> ConfigFile? {
        let expandedPath = (path as NSString).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expandedPath) else {
            return nil
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: expandedPath))
        return try JSONDecoder().decode(ConfigFile.self, from: data)
    }

    public func saveConfig(_ config: ConfigFile, to path: String) throws {
        let expandedPath = (path as NSString).expandingTildeInPath
        let dirPath = (expandedPath as NSString).deletingLastPathComponent

        if !FileManager.default.fileExists(atPath: dirPath) {
            try FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: URL(fileURLWithPath: expandedPath))

        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: expandedPath)
    }
}
