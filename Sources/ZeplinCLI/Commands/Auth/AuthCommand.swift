import ArgumentParser
import Foundation
import ZeplinKit

struct AuthCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "Manage authentication credentials",
        discussion: """
            Set up and manage Zeplin API credentials.

            Credentials are stored in ~/.zeplin/config.json with restricted permissions (600).
            You can configure multiple profiles for different accounts.

            GETTING A TOKEN
              1. Go to https://app.zeplin.io/profile/developer
              2. Under "Personal Access Tokens", click "Create new token"
              3. Give it a name and copy the token

            EXAMPLES
              Set up credentials interactively:
                $ zeplin-cli auth init

              Verify credentials work:
                $ zeplin-cli auth check

              List configured profiles:
                $ zeplin-cli auth profiles
            """,
        subcommands: [
            AuthInitCommand.self,
            AuthCheckCommand.self,
            AuthProfilesCommand.self,
            AuthUseCommand.self
        ]
    )
}

struct AuthInitCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Set up credentials interactively"
    )

    @Option(name: .long, help: "Profile name (default: 'default')")
    var profile: String = "default"

    @Flag(name: .long, help: "Overwrite existing profile")
    var force: Bool = false

    mutating func run() throws {
        let resolver = CredentialResolver()
        let configPath = CredentialResolver.globalConfigPath
        var config = try resolver.loadConfig(from: configPath) ?? ConfigFile()

        if config.profiles[profile] != nil && !force {
            print("Profile '\(profile)' already exists. Use --force to overwrite.")
            throw ExitCode.failure
        }

        print("Setting up Zeplin CLI credentials")
        print("==================================\n")
        print("You'll need a Personal Access Token from Zeplin:")
        print("  1. Go to https://app.zeplin.io/profile/developer")
        print("  2. Click \"Create new token\" under Personal Access Tokens")
        print("  3. Name it anything (e.g. \"cli\") and copy the token")
        print("  No special permissions or admin access required.\n")

        print("Personal Access Token:")
        print("> ", terminator: "")
        guard let token = readLine()?.trimmingCharacters(in: .whitespaces), !token.isEmpty else {
            print("Token is required")
            throw ExitCode.failure
        }

        print("\nOrganization ID (optional, press Enter to skip):")
        print("> ", terminator: "")
        let orgId = readLine()?.trimmingCharacters(in: .whitespaces)
        let organizationId = (orgId?.isEmpty ?? true) ? nil : orgId

        let newProfile = Profile(token: token, organizationId: organizationId)
        config.profiles[profile] = newProfile

        if config.defaultProfile == nil || profile == "default" {
            config.defaultProfile = profile
        }

        try resolver.saveConfig(config, to: configPath)

        print("\nCredentials saved to \(configPath)")
        print("  Profile: \(profile)")

        if config.defaultProfile == profile {
            print("  (set as default)")
        }

        print("\nVerifying credentials...")
        let credentials = newProfile.toCredentials()
        let client = APIClient(credentials: credentials)
        do {
            let user = try runAsync {
                try await client.getCurrentUser()
            }
            print("Credentials are valid. Logged in as \(user.username ?? user.email ?? user.id).")
        } catch {
            printError("Credentials were saved but verification failed: \(error.localizedDescription)")
            print("Check your personal access token.")
        }
    }
}

struct AuthCheckCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Verify credentials are valid"
    )

    @OptionGroup var options: GlobalOptions

    mutating func run() throws {
        let verbose = options.verbose
        printVerbose("Resolving credentials...", verbose: verbose)

        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        printVerbose("Making test API call...", verbose: verbose)

        do {
            let user = try runAsync {
                try await client.getCurrentUser()
            }
            print("Credentials are valid")
            print("  Username: \(user.username ?? "-")")
            print("  Email: \(user.email ?? "-")")
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct AuthProfilesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "profiles",
        abstract: "List configured profiles"
    )

    mutating func run() throws {
        let resolver = CredentialResolver()

        if let config = try resolver.loadConfig(from: CredentialResolver.globalConfigPath) {
            print("Global config (~/.zeplin/config.json):")
            print("  Default: \(config.defaultProfile ?? "(none)")")
            print("  Profiles:")
            for (name, profile) in config.profiles.sorted(by: { $0.key < $1.key }) {
                let marker = name == config.defaultProfile ? " *" : ""
                print("    - \(name)\(marker)")
                if let orgId = profile.organizationId {
                    print("      Organization: \(orgId)")
                }
            }
        } else {
            print("No global config found at ~/.zeplin/config.json")
        }

        if let config = try resolver.loadConfig(from: CredentialResolver.localConfigPath) {
            print("\nLocal config (.zeplin/config.json):")
            print("  Default: \(config.defaultProfile ?? "(none)")")
            print("  Profiles:")
            for (name, _) in config.profiles.sorted(by: { $0.key < $1.key }) {
                let marker = name == config.defaultProfile ? " *" : ""
                print("    - \(name)\(marker)")
            }
        }
    }
}

struct AuthUseCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "use",
        abstract: "Set the default profile"
    )

    @Argument(help: "Profile name to set as default")
    var profile: String

    @Flag(name: .long, help: "Update local config instead of global")
    var local: Bool = false

    mutating func run() throws {
        let resolver = CredentialResolver()
        let configPath = local ? CredentialResolver.localConfigPath : CredentialResolver.globalConfigPath

        guard var config = try resolver.loadConfig(from: configPath) else {
            print("No config file found at \(configPath)")
            throw ExitCode.failure
        }

        guard config.profiles[profile] != nil else {
            print("Profile '\(profile)' not found")
            print("Available profiles: \(config.profiles.keys.sorted().joined(separator: ", "))")
            throw ExitCode.failure
        }

        config.defaultProfile = profile
        try resolver.saveConfig(config, to: configPath)

        print("Default profile set to '\(profile)'")
    }
}
