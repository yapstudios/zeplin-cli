import ArgumentParser
import Foundation
import ZeplinKit

struct SpacingSectionsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "spacing-sections",
        abstract: "List spacing sections",
        discussion: """
            EXAMPLES
              List project spacing sections:
                $ zeplin-cli spacing-sections list --project <id> -o table

              List styleguide spacing sections:
                $ zeplin-cli spacing-sections list --styleguide <id> -o table
            """,
        subcommands: [
            SpacingSectionsListCommand.self,
        ]
    )
}

struct SpacingSectionsListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List spacing sections"
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
            printVerbose("Fetching spacing sections...", verbose: options.verbose)
            let sections: [SpacingSection] = try runAsync {
                if let pid = projectId {
                    if fetchAll { return try await client.listAllProjectSpacingSections(projectId: pid) }
                    if let limitVal { return try await client.paginate(totalLimit: limitVal) { l, o in try await client.listProjectSpacingSections(projectId: pid, limit: l, offset: o) } }
                    return try await client.listProjectSpacingSections(projectId: pid)
                } else {
                    if fetchAll { return try await client.listAllStyleguideSpacingSections(styleguideId: styleguideId!) }
                    if let limitVal { return try await client.paginate(totalLimit: limitVal) { l, o in try await client.listStyleguideSpacingSections(styleguideId: styleguideId!, limit: l, offset: o) } }
                    return try await client.listStyleguideSpacingSections(styleguideId: styleguideId!)
                }
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(sections)) }
            else { print(try formatter.format(sections)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
