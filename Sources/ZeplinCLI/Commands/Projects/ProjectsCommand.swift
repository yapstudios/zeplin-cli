import ArgumentParser
import Foundation
import ZeplinKit

struct ProjectsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "projects",
        abstract: "Manage projects (list, get)",
        discussion: """
            EXAMPLES
              List all projects:
                $ zeplin-cli projects list -o table

              Filter by organization:
                $ zeplin-cli projects list --organization <org-id>

              Filter by status:
                $ zeplin-cli projects list --status active

              Get project details:
                $ zeplin-cli projects get <id>
            """,
        subcommands: [
            ProjectsListCommand.self,
            ProjectsGetCommand.self
        ]
    )
}

struct ProjectsListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List projects"
    )

    @OptionGroup var options: GlobalOptions

    @Option(name: .customLong("org-id"), help: "Filter by organization ID")
    var orgId: String?

    @Option(name: .long, help: "Filter by status (active, archived)")
    var status: String?

    @Option(name: .long, help: "Filter by name (case-insensitive)")
    var name: String?

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

        let orgId = orgId ?? options.organization
        let statusFilter = status
        let nameFilter = name
        let limitVal = limit
        let fetchAll = all

        do {
            printVerbose("Fetching projects...", verbose: options.verbose)
            var projects: [Project] = try runAsync {
                if fetchAll {
                    return try await client.listAllProjects(organizationId: orgId)
                }
                if let limitVal {
                    return try await client.paginate(totalLimit: limitVal) { l, o in
                        try await client.listProjects(organizationId: orgId, limit: l, offset: o)
                    }
                }
                return try await client.listProjects(organizationId: orgId)
            }

            if !fetchAll && limitVal == nil && projects.count >= 100 {
                FileHandle.standardError.write(Data("Showing \(projects.count) results. Use --all or --limit <n> to fetch more.\n".utf8))
            }

            if let statusFilter {
                projects = projects.filter { $0.status?.lowercased() == statusFilter.lowercased() }
            }
            if let nameFilter {
                projects = projects.filter {
                    $0.name.localizedCaseInsensitiveContains(nameFilter)
                }
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

struct ProjectsGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get project details"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Project ID")
    var id: String

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let projectId = id
        do {
            printVerbose("Fetching project \(projectId)...", verbose: options.verbose)
            let project = try runAsync {
                try await client.getProject(id: projectId)
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(project))
            } else {
                print(try formatter.format(project))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
