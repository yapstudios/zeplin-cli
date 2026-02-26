import ArgumentParser
import Foundation
import ZeplinKit

struct WebhooksCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "webhooks",
        abstract: "Manage webhooks (list, create, get, update, delete)",
        discussion: """
            Webhooks are scoped to an organization, project, or styleguide.
            You must provide one of --organization, --project, or --styleguide.

            EXAMPLES
              List project webhooks:
                $ zeplin-cli webhooks list --project <id> -o table

              Create a webhook:
                $ zeplin-cli webhooks create --project <id> --url https://example.com/hook --events "project.screen"

              Delete a webhook:
                $ zeplin-cli webhooks delete <webhook-id> --project <id>
            """,
        subcommands: [
            WebhooksListCommand.self,
            WebhooksCreateCommand.self,
            WebhooksGetCommand.self,
            WebhooksUpdateCommand.self,
            WebhooksDeleteCommand.self
        ]
    )
}

private func resolveScope(orgId: String?, project: String?, styleguide: String?) throws -> (type: String, id: String) {
    if let id = orgId { return ("organization", id) }
    if let id = project { return ("project", id) }
    if let id = styleguide { return ("styleguide", id) }
    printError("One of --org-id, --project, or --styleguide is required")
    throw ExitCode.failure
}

struct WebhooksListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List webhooks"
    )

    @OptionGroup var options: GlobalOptions

    @Option(name: .customLong("org-id"), help: "Organization ID")
    var orgId: String?

    @Option(name: .long, help: "Project ID")
    var project: String?

    @Option(name: .long, help: "Styleguide ID")
    var styleguide: String?

    mutating func run() throws {
        let scope = try resolveScope(orgId: orgId, project: project, styleguide: styleguide)

        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        do {
            printVerbose("Fetching webhooks...", verbose: options.verbose)
            let webhooks: [Webhook] = try runAsync {
                switch scope.type {
                case "organization":
                    return try await client.listOrganizationWebhooks(organizationId: scope.id)
                case "project":
                    return try await client.listProjectWebhooks(projectId: scope.id)
                default:
                    return try await client.listStyleguideWebhooks(styleguideId: scope.id)
                }
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(webhooks))
            } else {
                print(try formatter.format(webhooks))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct WebhooksCreateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a webhook"
    )

    @OptionGroup var options: GlobalOptions

    @Option(name: .customLong("org-id"), help: "Organization ID")
    var orgId: String?

    @Option(name: .long, help: "Project ID")
    var project: String?

    @Option(name: .long, help: "Styleguide ID")
    var styleguide: String?

    @Option(name: .long, help: "Webhook URL")
    var url: String

    @Option(name: .long, help: "Comma-separated event types")
    var events: String

    mutating func run() throws {
        let scope = try resolveScope(orgId: orgId, project: project, styleguide: styleguide)

        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let webhookUrl = url
        let eventList = events.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        let body = WebhookCreateBody(url: webhookUrl, events: eventList)

        do {
            printVerbose("Creating webhook...", verbose: options.verbose)
            let webhook: Webhook = try runAsync {
                switch scope.type {
                case "organization":
                    return try await client.createOrganizationWebhook(organizationId: scope.id, body: body)
                case "project":
                    return try await client.createProjectWebhook(projectId: scope.id, body: body)
                default:
                    return try await client.createStyleguideWebhook(styleguideId: scope.id, body: body)
                }
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(webhook))
            } else {
                print("Webhook created: \(webhook.id)")
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct WebhooksGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get webhook details"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Webhook ID")
    var id: String

    @Option(name: .customLong("org-id"), help: "Organization ID")
    var orgId: String?

    @Option(name: .long, help: "Project ID")
    var project: String?

    @Option(name: .long, help: "Styleguide ID")
    var styleguide: String?

    mutating func run() throws {
        let scope = try resolveScope(orgId: orgId, project: project, styleguide: styleguide)

        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let webhookId = id

        do {
            printVerbose("Fetching webhook \(webhookId)...", verbose: options.verbose)
            let webhook: Webhook = try runAsync {
                switch scope.type {
                case "organization":
                    return try await client.getOrganizationWebhook(organizationId: scope.id, webhookId: webhookId)
                case "project":
                    return try await client.getProjectWebhook(projectId: scope.id, webhookId: webhookId)
                default:
                    return try await client.getStyleguideWebhook(styleguideId: scope.id, webhookId: webhookId)
                }
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(webhook))
            } else {
                print(try formatter.format(webhook))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct WebhooksUpdateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update a webhook"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Webhook ID")
    var id: String

    @Option(name: .customLong("org-id"), help: "Organization ID")
    var orgId: String?

    @Option(name: .long, help: "Project ID")
    var project: String?

    @Option(name: .long, help: "Styleguide ID")
    var styleguide: String?

    @Option(name: .long, help: "New webhook URL")
    var url: String?

    @Option(name: .long, help: "Comma-separated event types")
    var events: String?

    @Flag(name: .long, help: "Set webhook active")
    var active: Bool = false

    @Flag(name: .long, help: "Set webhook inactive")
    var inactive: Bool = false

    mutating func run() throws {
        let scope = try resolveScope(orgId: orgId, project: project, styleguide: styleguide)

        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let webhookId = id
        let eventList = events?.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        var status: String?
        if active { status = "active" }
        if inactive { status = "inactive" }
        let body = WebhookUpdateBody(url: url, events: eventList, status: status)

        do {
            printVerbose("Updating webhook \(webhookId)...", verbose: options.verbose)
            _ = try runAsync {
                switch scope.type {
                case "organization":
                    try await client.updateOrganizationWebhook(organizationId: scope.id, webhookId: webhookId, body: body)
                case "project":
                    try await client.updateProjectWebhook(projectId: scope.id, webhookId: webhookId, body: body)
                default:
                    try await client.updateStyleguideWebhook(styleguideId: scope.id, webhookId: webhookId, body: body)
                }
            }
            print("Webhook \(webhookId) updated")
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct WebhooksDeleteCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a webhook"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Webhook ID")
    var id: String

    @Option(name: .customLong("org-id"), help: "Organization ID")
    var orgId: String?

    @Option(name: .long, help: "Project ID")
    var project: String?

    @Option(name: .long, help: "Styleguide ID")
    var styleguide: String?

    mutating func run() throws {
        let scope = try resolveScope(orgId: orgId, project: project, styleguide: styleguide)

        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let webhookId = id

        do {
            printVerbose("Deleting webhook \(webhookId)...", verbose: options.verbose)
            try runAsync {
                switch scope.type {
                case "organization":
                    try await client.deleteOrganizationWebhook(organizationId: scope.id, webhookId: webhookId)
                case "project":
                    try await client.deleteProjectWebhook(projectId: scope.id, webhookId: webhookId)
                default:
                    try await client.deleteStyleguideWebhook(styleguideId: scope.id, webhookId: webhookId)
                }
            }
            print("Webhook \(webhookId) deleted")
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
