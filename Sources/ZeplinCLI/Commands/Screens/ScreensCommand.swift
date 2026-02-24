import ArgumentParser
import Foundation
import ZeplinKit

struct ScreensCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "screens",
        abstract: "Manage screens",
        discussion: """
            EXAMPLES
              List screens in a project:
                $ zeplin screens list <project-id> -o table

              Filter by section:
                $ zeplin screens list <project-id> --section <section-id>

              Get screen details:
                $ zeplin screens get <project-id> <screen-id>

              List screen versions:
                $ zeplin screens versions <project-id> <screen-id>
            """,
        subcommands: [
            ScreensListCommand.self,
            ScreensGetCommand.self,
            ScreensVersionsCommand.self
        ]
    )
}

struct ScreensListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List screens in a project"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Project ID")
    var projectId: String

    @Option(name: .long, help: "Filter by section ID")
    var section: String?

    @Option(name: .long, help: "Filter by name (case-insensitive)")
    var name: String?

    @Option(name: .long, help: "Filter by tag")
    var tag: String?

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

        let pid = projectId
        let sectionId = section
        let nameFilter = name
        let tagFilter = tag
        let limitVal = limit
        let fetchAll = all

        do {
            printVerbose("Fetching screens...", verbose: options.verbose)
            var screens: [Screen] = try runAsync {
                if fetchAll {
                    return try await client.listAllScreens(projectId: pid, sectionId: sectionId)
                }
                return try await client.listScreens(projectId: pid, sectionId: sectionId, limit: limitVal)
            }

            if let nameFilter {
                screens = screens.filter {
                    $0.name.localizedCaseInsensitiveContains(nameFilter)
                }
            }
            if let tagFilter {
                screens = screens.filter {
                    $0.tags?.contains(where: { $0.localizedCaseInsensitiveContains(tagFilter) }) == true
                }
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(screens))
            } else {
                print(try formatter.format(screens))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ScreensGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get screen details"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Project ID")
    var projectId: String

    @Argument(help: "Screen ID")
    var screenId: String

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let pid = projectId
        let sid = screenId

        do {
            printVerbose("Fetching screen \(sid)...", verbose: options.verbose)
            let screen = try runAsync {
                try await client.getScreen(projectId: pid, screenId: sid)
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(screen))
            } else {
                print(try formatter.format(screen))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct ScreensVersionsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "versions",
        abstract: "List screen versions"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Project ID")
    var projectId: String

    @Argument(help: "Screen ID")
    var screenId: String

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

        let pid = projectId
        let sid = screenId
        let limitVal = limit
        let fetchAll = all

        do {
            printVerbose("Fetching screen versions...", verbose: options.verbose)
            let versions: [ScreenVersion] = try runAsync {
                if fetchAll {
                    return try await client.listAllScreenVersions(projectId: pid, screenId: sid)
                }
                return try await client.listScreenVersions(projectId: pid, screenId: sid, limit: limitVal)
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(versions))
            } else {
                print(try formatter.format(versions))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
