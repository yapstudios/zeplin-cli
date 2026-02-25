import ArgumentParser
import Foundation
import ZeplinKit

struct UserCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "user",
        abstract: "User info and resources",
        discussion: """
            EXAMPLES
              Show current user:
                $ zeplin user

              List user's projects:
                $ zeplin user projects -o table

              List user's styleguides:
                $ zeplin user styleguides -o table

              List user's webhooks:
                $ zeplin user webhooks -o table
            """,
        subcommands: [
            UserProfileCommand.self,
            UserProjectsCommand.self,
            UserStyleguidesCommand.self,
            UserWebhooksCommand.self,
            UserWebhookGetCommand.self,
        ],
        defaultSubcommand: UserProfileCommand.self
    )
}

struct UserProfileCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "profile",
        abstract: "Show current user info"
    )

    @OptionGroup var options: GlobalOptions

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        do {
            printVerbose("Fetching current user...", verbose: options.verbose)
            let user = try runAsync {
                try await client.getCurrentUser()
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(user))
            } else {
                print(try formatter.format(user))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct UserProjectsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "projects",
        abstract: "List user's projects"
    )

    @OptionGroup var options: GlobalOptions

    @Option(name: .long, help: "Maximum number of results")
    var limit: Int?

    @Flag(name: .long, help: "Fetch all pages of results")
    var all: Bool = false

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let limitVal = limit
        let fetchAll = all

        do {
            printVerbose("Fetching user projects...", verbose: options.verbose)
            let projects: [Project] = try runAsync {
                if fetchAll {
                    return try await client.listAllUserProjects()
                }
                return try await client.listUserProjects(limit: limitVal)
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(projects))
            } else {
                print(try formatter.format(projects))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct UserStyleguidesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "styleguides",
        abstract: "List user's styleguides"
    )

    @OptionGroup var options: GlobalOptions

    @Option(name: .long, help: "Maximum number of results")
    var limit: Int?

    @Flag(name: .long, help: "Fetch all pages of results")
    var all: Bool = false

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let limitVal = limit
        let fetchAll = all

        do {
            printVerbose("Fetching user styleguides...", verbose: options.verbose)
            let styleguides: [Styleguide] = try runAsync {
                if fetchAll {
                    return try await client.listAllUserStyleguides()
                }
                return try await client.listUserStyleguides(limit: limitVal)
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(styleguides))
            } else {
                print(try formatter.format(styleguides))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct UserWebhooksCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "webhooks",
        abstract: "List user's webhooks"
    )

    @OptionGroup var options: GlobalOptions

    @Option(name: .long, help: "Maximum number of results")
    var limit: Int?

    @Flag(name: .long, help: "Fetch all pages of results")
    var all: Bool = false

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let limitVal = limit
        let fetchAll = all

        do {
            printVerbose("Fetching user webhooks...", verbose: options.verbose)
            let webhooks: [UserWebhook] = try runAsync {
                if fetchAll {
                    return try await client.listAllUserWebhooks()
                }
                return try await client.listUserWebhooks(limit: limitVal)
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(webhooks))
            } else {
                print(try formatter.format(webhooks))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct UserWebhookGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "webhook",
        abstract: "Get a user webhook"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Webhook ID")
    var id: String

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let webhookId = id
        do {
            printVerbose("Fetching webhook \(webhookId)...", verbose: options.verbose)
            let webhook = try runAsync {
                try await client.getUserWebhook(webhookId: webhookId)
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(webhook))
            } else {
                print(try formatter.format(webhook))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
