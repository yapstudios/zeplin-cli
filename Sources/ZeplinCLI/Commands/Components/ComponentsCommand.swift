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
                $ zeplin-cli components list --project <id> -o table

              List components in a styleguide:
                $ zeplin-cli components list --styleguide <id> -o table

              Get component details:
                $ zeplin-cli components get <component-id> --project <id>

              Get latest component version:
                $ zeplin-cli components version-latest <component-id> --project <id>

              List connected components:
                $ zeplin-cli components connected --project <id> -o table
            """,
        subcommands: [
            ComponentsListCommand.self,
            ComponentsGetCommand.self,
            ComponentsVersionLatestCommand.self,
            ComponentsConnectedCommand.self,
            ComponentsSectionsCommand.self,
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

struct ComponentsVersionLatestCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version-latest",
        abstract: "Get the latest component version"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Component ID") var id: String
    @Option(name: .long, help: "Project ID") var project: String?
    @Option(name: .long, help: "Styleguide ID") var styleguide: String?

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

        let componentId = id, projectId = project, styleguideId = styleguide

        do {
            printVerbose("Fetching latest version...", verbose: options.verbose)
            let version: ComponentVersion = try runAsync {
                if let pid = projectId {
                    return try await client.getProjectComponentLatestVersion(projectId: pid, componentId: componentId)
                } else {
                    return try await client.getStyleguideComponentLatestVersion(styleguideId: styleguideId!, componentId: componentId)
                }
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(version)) }
            else { print(try formatter.format(version)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ComponentsConnectedCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "connected",
        abstract: "List connected components"
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
            printVerbose("Fetching connected components...", verbose: options.verbose)
            let connected: [ConnectedComponent] = try runAsync {
                if let pid = projectId {
                    if fetchAll { return try await client.listAllProjectConnectedComponents(projectId: pid) }
                    return try await client.listProjectConnectedComponents(projectId: pid, limit: limitVal)
                } else {
                    if fetchAll { return try await client.listAllStyleguideConnectedComponents(styleguideId: styleguideId!) }
                    return try await client.listStyleguideConnectedComponents(styleguideId: styleguideId!, limit: limitVal)
                }
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(connected)) }
            else { print(try formatter.format(connected)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ComponentsSectionsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sections",
        abstract: "List component sections"
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
            printVerbose("Fetching component sections...", verbose: options.verbose)
            let sections: [ComponentSection] = try runAsync {
                if let pid = projectId {
                    if fetchAll { return try await client.listAllProjectComponentSections(projectId: pid) }
                    return try await client.listProjectComponentSections(projectId: pid, limit: limitVal)
                } else {
                    if fetchAll { return try await client.listAllStyleguideComponentSections(styleguideId: styleguideId!) }
                    return try await client.listStyleguideComponentSections(styleguideId: styleguideId!, limit: limitVal)
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
