import ArgumentParser
import Foundation
import ZeplinKit

struct VariablesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "variables",
        abstract: "List variable collections",
        discussion: """
            EXAMPLES
              List project variables:
                $ zeplin variables list --project <id> -o table

              List styleguide variables:
                $ zeplin variables list --styleguide <id> -o table
            """,
        subcommands: [
            VariablesListCommand.self,
        ]
    )
}

struct VariablesListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List variable collections"
    )

    @OptionGroup var options: GlobalOptions
    @Option(name: .long, help: "Project ID") var project: String?
    @Option(name: .long, help: "Styleguide ID") var styleguide: String?
    @Option(name: .long, help: "Maximum number of results") var limit: Int?
    @Flag(name: .long, help: "Fetch all pages of results") var all: Bool = false

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

        let projectId = project, styleguideId = styleguide, limitVal = limit, fetchAll = all

        do {
            printVerbose("Fetching variables...", verbose: options.verbose)
            let variables: [VariableCollection] = try runAsync {
                if let pid = projectId {
                    if fetchAll { return try await client.listAllProjectVariables(projectId: pid) }
                    return try await client.listProjectVariables(projectId: pid, limit: limitVal)
                } else {
                    if fetchAll { return try await client.listAllStyleguideVariables(styleguideId: styleguideId!) }
                    return try await client.listStyleguideVariables(styleguideId: styleguideId!, limit: limitVal)
                }
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(variables)) }
            else { print(try formatter.format(variables)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
