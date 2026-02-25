import ArgumentParser
import Foundation
import ZeplinKit

struct StyleguidesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "styleguides",
        abstract: "Manage styleguides",
        discussion: """
            EXAMPLES
              List all styleguides:
                $ zeplin-cli styleguides list -o table

              Get styleguide details:
                $ zeplin-cli styleguides get <id>

              List linked projects:
                $ zeplin-cli styleguides linked-projects <id> -o table
            """,
        subcommands: [
            StyleguidesListCommand.self,
            StyleguidesGetCommand.self,
            StyleguidesLinkedProjectsCommand.self,
        ]
    )
}

struct StyleguidesListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List styleguides"
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
            printVerbose("Fetching styleguides...", verbose: options.verbose)
            let styleguides: [Styleguide] = try runAsync {
                if fetchAll {
                    return try await client.listAllStyleguides()
                }
                return try await client.listStyleguides(limit: limitVal)
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

struct StyleguidesGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get styleguide details"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Styleguide ID")
    var id: String

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let styleguideId = id
        do {
            printVerbose("Fetching styleguide \(styleguideId)...", verbose: options.verbose)
            let styleguide = try runAsync {
                try await client.getStyleguide(id: styleguideId)
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(styleguide))
            } else {
                print(try formatter.format(styleguide))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct StyleguidesLinkedProjectsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "linked-projects",
        abstract: "List projects linked to a styleguide"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Styleguide ID") var id: String
    @Option(name: .long, help: "Maximum number of results") var limit: Int?
    @Flag(name: .long, help: "Fetch all pages of results") var all: Bool = false

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let sgId = id, limitVal = limit, fetchAll = all

        do {
            printVerbose("Fetching linked projects...", verbose: options.verbose)
            let projects: [Project] = try runAsync {
                if fetchAll { return try await client.listAllStyleguideLinkedProjects(styleguideId: sgId) }
                return try await client.listStyleguideLinkedProjects(styleguideId: sgId, limit: limitVal)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(projects)) }
            else { print(try formatter.format(projects)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
