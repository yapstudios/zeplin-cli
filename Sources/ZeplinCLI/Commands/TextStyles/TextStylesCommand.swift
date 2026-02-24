import ArgumentParser
import Foundation
import ZeplinKit

struct TextStylesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "text-styles",
        abstract: "List text styles",
        subcommands: [
            TextStylesListCommand.self
        ]
    )
}

struct TextStylesListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List text styles"
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
            printVerbose("Fetching text styles...", verbose: options.verbose)
            let textStyles: [TextStyle] = try runAsync {
                if let pid = projectId {
                    return try await client.listProjectTextStyles(projectId: pid)
                } else {
                    return try await client.listStyleguideTextStyles(styleguideId: styleguideId!)
                }
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(textStyles))
            } else {
                print(try formatter.format(textStyles))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
