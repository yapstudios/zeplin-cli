import ArgumentParser
import Foundation
import ZeplinKit

struct SpacingCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "spacing",
        abstract: "List spacing tokens",
        subcommands: [
            SpacingListCommand.self
        ]
    )
}

struct SpacingListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List spacing tokens"
    )

    @OptionGroup var options: GlobalOptions

    @Option(name: .long, help: "Project ID")
    var project: String?

    @Option(name: .long, help: "Styleguide ID")
    var styleguide: String?

    mutating func run() throws {
        guard project != nil || styleguide != nil else {
            printError("Either --project or --styleguide is required")
            throw ExitCode.failure
        }

        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let projectId = project
        let styleguideId = styleguide

        do {
            printVerbose("Fetching spacing tokens...", verbose: options.verbose)
            let tokens: [SpacingToken] = try runAsync {
                if let pid = projectId {
                    return try await client.listProjectSpacingTokens(projectId: pid)
                } else {
                    return try await client.listStyleguideSpacingTokens(styleguideId: styleguideId!)
                }
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(tokens))
            } else {
                print(try formatter.format(tokens))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
