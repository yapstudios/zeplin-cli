import ArgumentParser
import Foundation

public struct Zeplin: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "zeplin-cli",
        abstract: "A command-line interface for the Zeplin API",
        discussion: """
            Interact with Zeplin via the REST API.

            INTERACTIVE MODE
              Run 'zeplin-cli' with no arguments to launch interactive mode.
              Navigate with arrow keys, select with Enter, quit with 'q'.

            AUTHENTICATION
              Credentials can be provided via:
              1. Command-line flag (--token)
              2. Environment variable (ZEPLIN_TOKEN)
              3. Project-local config (.zeplin/config.json)
              4. Global config (~/.zeplin/config.json)

              Run 'zeplin-cli auth init' to set up credentials interactively.
              Get a personal access token at https://app.zeplin.io/profile/developer

            EXAMPLES
              Launch interactive mode:
                $ zeplin-cli

              List all projects:
                $ zeplin-cli projects list -o table

              List screens in a project:
                $ zeplin-cli screens list <project-id> -o table

              Get project colors:
                $ zeplin-cli colors list --project <project-id> -o table

              Show current user:
                $ zeplin-cli user

            ALL COMMANDS
              Run 'zeplin-cli help-all' to see every command and subcommand.
              Run 'zeplin-cli dump-commands' for machine-readable JSON output.

            DOCUMENTATION
              https://docs.zeplin.dev/reference/introduction
            """,
        version: "0.3.1",
        subcommands: [
            InteractiveCommand.self,
            AuthCommand.self,
            OrganizationsCommand.self,
            ProjectsCommand.self,
            ScreensCommand.self,
            ComponentsCommand.self,
            StyleguidesCommand.self,
            ColorsCommand.self,
            TextStylesCommand.self,
            SpacingCommand.self,
            DesignTokensCommand.self,
            FlowsCommand.self,
            MembersCommand.self,
            WebhooksCommand.self,
            NotificationsCommand.self,
            UserCommand.self,
            PagesCommand.self,
            SpacingSectionsCommand.self,
            VariablesCommand.self,
            HelpAllCommand.self,
            DumpCommandsCommand.self,
        ],
        defaultSubcommand: InteractiveCommand.self
    )

    public init() {}
}

func printError(_ message: String) {
    FileHandle.standardError.write(Data("error: \(message)\n".utf8))
}

func printVerbose(_ message: String, verbose: Bool) {
    guard verbose else { return }
    FileHandle.standardError.write(Data("[\(message)]\n".utf8))
}

func sendNotification(title: String, message: String) {
    let script = "display notification \"\(message)\" with title \"\(title)\""
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", script]
    try? process.run()
}

func runAsync<T: Sendable>(_ block: @escaping @Sendable () async throws -> T) throws -> T {
    let semaphore = DispatchSemaphore(value: 0)
    nonisolated(unsafe) var result: Result<T, Error>?

    Task { @Sendable in
        do {
            let value = try await block()
            result = .success(value)
        } catch {
            result = .failure(error)
        }
        semaphore.signal()
    }

    semaphore.wait()

    switch result! {
    case .success(let value):
        return value
    case .failure(let error):
        throw error
    }
}
