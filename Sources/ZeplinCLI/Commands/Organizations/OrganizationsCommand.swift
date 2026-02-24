import ArgumentParser
import Foundation
import ZeplinKit

struct OrganizationsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "organizations",
        abstract: "Manage organizations",
        discussion: """
            EXAMPLES
              List organizations:
                $ zeplin organizations list -o table

              Get organization details:
                $ zeplin organizations get <id>
            """,
        subcommands: [
            OrganizationsListCommand.self,
            OrganizationsGetCommand.self
        ]
    )
}

struct OrganizationsListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List organizations"
    )

    @OptionGroup var options: GlobalOptions

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        do {
            printVerbose("Fetching organizations...", verbose: options.verbose)
            let orgs = try runAsync {
                try await client.listOrganizations()
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(orgs))
            } else {
                print(try formatter.format(orgs))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct OrganizationsGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get organization details"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Organization ID")
    var id: String

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let orgId = id
        do {
            printVerbose("Fetching organization \(orgId)...", verbose: options.verbose)
            let org = try runAsync {
                try await client.getOrganization(id: orgId)
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(org))
            } else {
                print(try formatter.format(org))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
