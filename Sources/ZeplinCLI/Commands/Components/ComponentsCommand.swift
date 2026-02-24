import ArgumentParser
import Foundation
import ZeplinKit

struct ComponentsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "components",
        abstract: "Manage components",
        discussion: """
            EXAMPLES
              List components in a project:
                $ zeplin components list --project <id> -o table

              List components in a styleguide:
                $ zeplin components list --styleguide <id> -o table

              Get component details:
                $ zeplin components get <component-id> --project <id>
            """,
        subcommands: [
            ComponentsListCommand.self,
            ComponentsGetCommand.self
        ]
    )
}

struct ComponentsListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List components"
    )

    @OptionGroup var options: GlobalOptions

    @Option(name: .long, help: "Project ID")
    var project: String?

    @Option(name: .long, help: "Styleguide ID")
    var styleguide: String?

    @Option(name: .long, help: "Filter by name (case-insensitive)")
    var name: String?

    @Option(name: .long, help: "Maximum number of results")
    var limit: Int?

    @Flag(name: .long, help: "Fetch all pages of results")
    var all: Bool = false

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
        let nameFilter = name
        let limitVal = limit
        let fetchAll = all

        do {
            printVerbose("Fetching components...", verbose: options.verbose)
            var components: [Component] = try runAsync {
                if let pid = projectId {
                    if fetchAll {
                        return try await client.listAllProjectComponents(projectId: pid)
                    }
                    return try await client.listProjectComponents(projectId: pid, limit: limitVal)
                } else if let sid = styleguideId {
                    if fetchAll {
                        return try await client.listAllStyleguideComponents(styleguideId: sid)
                    }
                    return try await client.listStyleguideComponents(styleguideId: sid, limit: limitVal)
                }
                return []
            }

            if let nameFilter {
                components = components.filter {
                    $0.name.localizedCaseInsensitiveContains(nameFilter)
                }
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(components))
            } else {
                print(try formatter.format(components))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ComponentsGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get component details"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Component ID")
    var id: String

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

        let componentId = id
        let projectId = project
        let styleguideId = styleguide

        do {
            printVerbose("Fetching component \(componentId)...", verbose: options.verbose)
            let component: Component = try runAsync {
                if let pid = projectId {
                    return try await client.getProjectComponent(projectId: pid, componentId: componentId)
                } else {
                    return try await client.getStyleguideComponent(styleguideId: styleguideId!, componentId: componentId)
                }
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(component))
            } else {
                print(try formatter.format(component))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
