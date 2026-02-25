import ArgumentParser
import Foundation
import ZeplinKit

struct PagesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pages",
        abstract: "List pages",
        discussion: """
            EXAMPLES
              List project pages:
                $ zeplin pages list --project <id> -o table

              List styleguide pages:
                $ zeplin pages list --styleguide <id> -o table
            """,
        subcommands: [
            PagesListCommand.self,
        ]
    )
}

struct PagesListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List pages"
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
            printVerbose("Fetching pages...", verbose: options.verbose)
            let pages: [Page] = try runAsync {
                if let pid = projectId {
                    if fetchAll { return try await client.listAllProjectPages(projectId: pid) }
                    return try await client.listProjectPages(projectId: pid, limit: limitVal)
                } else {
                    if fetchAll { return try await client.listAllStyleguidePages(styleguideId: styleguideId!) }
                    return try await client.listStyleguidePages(styleguideId: styleguideId!, limit: limitVal)
                }
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(pages)) }
            else { print(try formatter.format(pages)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
