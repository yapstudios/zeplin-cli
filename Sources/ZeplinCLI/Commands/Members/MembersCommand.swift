import ArgumentParser
import Foundation
import ZeplinKit

struct MembersCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "members",
        abstract: "Manage members",
        discussion: """
            EXAMPLES
              List organization members:
                $ zeplin-cli members list --organization <id> -o table

              List project members:
                $ zeplin-cli members list --project <id> -o table

              Invite a member to an organization:
                $ zeplin-cli members invite <org-id> --email user@example.com --role editor
            """,
        subcommands: [
            MembersListCommand.self,
            MembersInviteCommand.self
        ]
    )
}

struct MembersListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List members"
    )

    @OptionGroup var options: GlobalOptions

    @Option(name: .customLong("org-id"), help: "Organization ID")
    var orgId: String?

    @Option(name: .long, help: "Project ID")
    var project: String?

    @Option(name: .long, help: "Styleguide ID")
    var styleguide: String?

    @Option(name: .long, help: "Maximum number of results")
    var limit: Int?

    @Flag(name: .long, help: "Fetch all pages of results")
    var all: Bool = false

    mutating func run() throws {
        guard orgId != nil || project != nil || styleguide != nil else {
            printError("One of --org-id, --project, or --styleguide is required")
            throw ExitCode.failure
        }

        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let orgId = orgId
        let projectId = project
        let styleguideId = styleguide
        let limitVal = limit
        let fetchAll = all

        do {
            printVerbose("Fetching members...", verbose: options.verbose)
            let formatter = options.outputFormatter()

            if let orgId {
                let members: [OrganizationMember] = try runAsync {
                    if fetchAll {
                        return try await client.listAllOrganizationMembers(organizationId: orgId)
                    }
                    return try await client.listOrganizationMembers(organizationId: orgId, limit: limitVal)
                }
                if options.output == .json {
                    print(try formatter.formatRawJSON(members))
                } else {
                    print(try formatter.format(members))
                }
            } else if let projectId {
                let members: [ProjectMember] = try runAsync {
                    if fetchAll {
                        return try await client.listAllProjectMembers(projectId: projectId)
                    }
                    return try await client.listProjectMembers(projectId: projectId, limit: limitVal)
                }
                if options.output == .json {
                    print(try formatter.formatRawJSON(members))
                } else {
                    print(try formatter.format(members))
                }
            } else if let styleguideId {
                let members: [StyleguideMember] = try runAsync {
                    if fetchAll {
                        return try await client.listAllStyleguideMembers(styleguideId: styleguideId)
                    }
                    return try await client.listStyleguideMembers(styleguideId: styleguideId, limit: limitVal)
                }
                if options.output == .json {
                    print(try formatter.formatRawJSON(members))
                } else {
                    print(try formatter.format(members))
                }
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct MembersInviteCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "invite",
        abstract: "Invite a member to an organization"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Organization ID")
    var organizationId: String

    @Option(name: .long, help: "Email address to invite")
    var email: String

    @Option(name: .long, help: "Role (admin, editor, member)")
    var role: String = "member"

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let orgId = organizationId
        let inviteEmail = email
        let inviteRole = role

        do {
            printVerbose("Inviting \(inviteEmail) to organization...", verbose: options.verbose)
            let body: [String: String] = ["handle": inviteEmail, "role": inviteRole]
            try runAsync {
                try await client.inviteOrganizationMember(organizationId: orgId, body: body)
            }
            print("Invitation sent to \(inviteEmail)")
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
