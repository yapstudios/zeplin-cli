import ArgumentParser
import Foundation
import ZeplinKit

struct FlowsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "flows",
        abstract: "Manage flow boards",
        discussion: """
            EXAMPLES
              List flow boards in a project:
                $ zeplin flows list <project-id> -o table

              Get flow board details:
                $ zeplin flows get <project-id> <board-id>

              List nodes in a flow board:
                $ zeplin flows nodes <project-id> <board-id> -o table

              List connectors:
                $ zeplin flows connectors <project-id> <board-id> -o table

              Get a specific node:
                $ zeplin flows node <project-id> <board-id> <node-id>
            """,
        subcommands: [
            FlowsListCommand.self,
            FlowsGetCommand.self,
            FlowsNodesCommand.self,
            FlowsNodeGetCommand.self,
            FlowsConnectorsCommand.self,
            FlowsConnectorGetCommand.self,
            FlowsGroupsCommand.self,
        ]
    )
}

struct FlowsListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List flow boards in a project"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Project ID")
    var projectId: String

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
        let limitVal = limit
        let fetchAll = all

        do {
            printVerbose("Fetching flow boards...", verbose: options.verbose)
            let boards: [FlowBoard] = try runAsync {
                if fetchAll {
                    return try await client.listAllFlowBoards(projectId: pid)
                }
                return try await client.listFlowBoards(projectId: pid, limit: limitVal)
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(boards))
            } else {
                print(try formatter.format(boards))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct FlowsGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get flow board details"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Project ID")
    var projectId: String

    @Argument(help: "Flow board ID")
    var boardId: String

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let pid = projectId
        let bid = boardId

        do {
            printVerbose("Fetching flow board \(bid)...", verbose: options.verbose)
            let board = try runAsync {
                try await client.getFlowBoard(projectId: pid, boardId: bid)
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(board))
            } else {
                print(try formatter.format(board))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct FlowsNodesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "nodes",
        abstract: "List nodes in a flow board"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Project ID")
    var projectId: String

    @Argument(help: "Flow board ID")
    var boardId: String

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
        let bid = boardId
        let limitVal = limit
        let fetchAll = all

        do {
            printVerbose("Fetching flow board nodes...", verbose: options.verbose)
            let nodes: [FlowBoardNode] = try runAsync {
                if fetchAll {
                    return try await client.listAllFlowBoardNodes(projectId: pid, boardId: bid)
                }
                return try await client.listFlowBoardNodes(projectId: pid, boardId: bid, limit: limitVal)
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(nodes))
            } else {
                print(try formatter.format(nodes))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct FlowsNodeGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "node",
        abstract: "Get a specific flow board node"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Project ID") var projectId: String
    @Argument(help: "Flow board ID") var boardId: String
    @Argument(help: "Node ID") var nodeId: String

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let pid = projectId, bid = boardId, nid = nodeId

        do {
            printVerbose("Fetching node \(nid)...", verbose: options.verbose)
            let node = try runAsync {
                try await client.getFlowBoardNode(projectId: pid, boardId: bid, nodeId: nid)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(node)) }
            else { print(try formatter.format(node)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct FlowsConnectorsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "connectors",
        abstract: "List connectors in a flow board"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Project ID")
    var projectId: String

    @Argument(help: "Flow board ID")
    var boardId: String

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
        let bid = boardId
        let limitVal = limit
        let fetchAll = all

        do {
            printVerbose("Fetching flow board connectors...", verbose: options.verbose)
            let connectors: [FlowBoardConnector] = try runAsync {
                if fetchAll {
                    return try await client.listAllFlowBoardConnectors(projectId: pid, boardId: bid)
                }
                return try await client.listFlowBoardConnectors(projectId: pid, boardId: bid, limit: limitVal)
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(connectors))
            } else {
                print(try formatter.format(connectors))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct FlowsConnectorGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "connector",
        abstract: "Get a specific flow board connector"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Project ID") var projectId: String
    @Argument(help: "Flow board ID") var boardId: String
    @Argument(help: "Connector ID") var connectorId: String

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let pid = projectId, bid = boardId, cid = connectorId

        do {
            printVerbose("Fetching connector \(cid)...", verbose: options.verbose)
            let connector = try runAsync {
                try await client.getFlowBoardConnector(projectId: pid, boardId: bid, connectorId: cid)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(connector)) }
            else { print(try formatter.format(connector)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct FlowsGroupsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "groups",
        abstract: "List groups in a flow board"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Project ID") var projectId: String
    @Argument(help: "Flow board ID") var boardId: String

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let pid = projectId, bid = boardId

        do {
            printVerbose("Fetching flow board groups...", verbose: options.verbose)
            let groups: [FlowBoardGroup] = try runAsync {
                try await client.listFlowBoardGroups(projectId: pid, boardId: bid)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(groups)) }
            else { print(try formatter.format(groups)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
