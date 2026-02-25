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

              List organization styleguides:
                $ zeplin organizations styleguides <id> -o table
            """,
        subcommands: [
            OrganizationsListCommand.self,
            OrganizationsGetCommand.self,
            OrganizationsStyleguidesCommand.self,
            OrganizationsWorkflowStatusesCommand.self,
            OrganizationsAliensCommand.self,
            OrganizationsMemberProjectsCommand.self,
            OrganizationsMemberStyleguidesCommand.self,
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

struct OrganizationsStyleguidesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "styleguides",
        abstract: "List organization styleguides"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Organization ID") var id: String
    @Option(name: .long, help: "Maximum number of results") var limit: Int?
    @Flag(name: .long, help: "Fetch all pages of results") var all: Bool = false

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let orgId = id, limitVal = limit, fetchAll = all

        do {
            printVerbose("Fetching organization styleguides...", verbose: options.verbose)
            let styleguides: [Styleguide] = try runAsync {
                if fetchAll { return try await client.listAllOrganizationStyleguides(organizationId: orgId) }
                return try await client.listOrganizationStyleguides(organizationId: orgId, limit: limitVal)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(styleguides)) }
            else { print(try formatter.format(styleguides)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct OrganizationsWorkflowStatusesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "workflow-statuses",
        abstract: "List organization workflow statuses"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Organization ID") var id: String

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
            printVerbose("Fetching workflow statuses...", verbose: options.verbose)
            let statuses: [WorkflowStatus] = try runAsync {
                try await client.listOrganizationWorkflowStatuses(organizationId: orgId)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(statuses)) }
            else { print(try formatter.format(statuses)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct OrganizationsAliensCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "aliens",
        abstract: "List organization aliens (external collaborators)"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Organization ID") var id: String

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
            printVerbose("Fetching aliens...", verbose: options.verbose)
            let aliens: [OrganizationMember] = try runAsync {
                try await client.listOrganizationAliens(organizationId: orgId)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(aliens)) }
            else { print(try formatter.format(aliens)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct OrganizationsMemberProjectsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "member-projects",
        abstract: "List projects accessible to an organization member"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Organization ID") var organizationId: String
    @Argument(help: "Member ID") var memberId: String
    @Option(name: .long, help: "Maximum number of results") var limit: Int?
    @Flag(name: .long, help: "Fetch all pages of results") var all: Bool = false

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let orgId = organizationId, mid = memberId, limitVal = limit, fetchAll = all

        do {
            printVerbose("Fetching member projects...", verbose: options.verbose)
            let projects: [Project] = try runAsync {
                if fetchAll { return try await client.listAllOrganizationMemberProjects(organizationId: orgId, memberId: mid) }
                return try await client.listOrganizationMemberProjects(organizationId: orgId, memberId: mid, limit: limitVal)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(projects)) }
            else { print(try formatter.format(projects)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct OrganizationsMemberStyleguidesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "member-styleguides",
        abstract: "List styleguides accessible to an organization member"
    )

    @OptionGroup var options: GlobalOptions
    @Argument(help: "Organization ID") var organizationId: String
    @Argument(help: "Member ID") var memberId: String
    @Option(name: .long, help: "Maximum number of results") var limit: Int?
    @Flag(name: .long, help: "Fetch all pages of results") var all: Bool = false

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let orgId = organizationId, mid = memberId, limitVal = limit, fetchAll = all

        do {
            printVerbose("Fetching member styleguides...", verbose: options.verbose)
            let styleguides: [Styleguide] = try runAsync {
                if fetchAll { return try await client.listAllOrganizationMemberStyleguides(organizationId: orgId, memberId: mid) }
                return try await client.listOrganizationMemberStyleguides(organizationId: orgId, memberId: mid, limit: limitVal)
            }
            let formatter = options.outputFormatter()
            if options.output == .json { print(try formatter.formatRawJSON(styleguides)) }
            else { print(try formatter.format(styleguides)) }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
