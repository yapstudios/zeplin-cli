import ArgumentParser
import Foundation
import ZeplinKit

struct ColorsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "colors",
        abstract: "List colors",
        discussion: """
            EXAMPLES
              List project colors:
                $ zeplin-cli colors list --project <id> -o table

              List styleguide colors:
                $ zeplin-cli colors list --styleguide <id> -o table
            """,
        subcommands: [
            ColorsListCommand.self
        ]
    )
}

struct ColorsListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List colors"
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
            printVerbose("Fetching colors...", verbose: options.verbose)
            let colors: [Color] = try runAsync {
                if let pid = projectId {
                    return try await client.listProjectColors(projectId: pid)
                } else {
                    return try await client.listStyleguideColors(styleguideId: styleguideId!)
                }
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(colors))
            } else {
                print(try formatter.format(colors))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
