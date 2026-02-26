import ArgumentParser
import Foundation
import ZeplinKit

struct NotificationsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "notifications",
        abstract: "Manage notifications (list, read)",
        discussion: """
            EXAMPLES
              List notifications:
                $ zeplin-cli notifications list -o table

              List unread only:
                $ zeplin-cli notifications list --unread

              Mark as read:
                $ zeplin-cli notifications read <notification-id>
            """,
        subcommands: [
            NotificationsListCommand.self,
            NotificationsReadCommand.self
        ]
    )
}

struct NotificationsListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List notifications"
    )

    @OptionGroup var options: GlobalOptions

    @Flag(name: .long, help: "Show only unread notifications")
    var unread: Bool = false

    @Option(name: .long, help: "Maximum number of results")
    var limit: Int?

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let limitVal = limit
        let unreadOnly = unread

        do {
            printVerbose("Fetching notifications...", verbose: options.verbose)
            var notifications: [ZeplinNotification] = try runAsync {
                if let limitVal {
                    return try await client.paginate(totalLimit: limitVal) { l, o in try await client.listNotifications(limit: l, offset: o) }
                }
                return try await client.listNotifications()
            }

            if unreadOnly {
                notifications = notifications.filter { $0.isRead == false }
            }

            let formatter = options.outputFormatter()
            if options.output == .json {
                print(try formatter.formatRawJSON(notifications))
            } else {
                print(try formatter.format(notifications))
            }
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}

struct NotificationsReadCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "read",
        abstract: "Mark a notification as read"
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Notification ID")
    var id: String

    mutating func run() throws {
        let client: APIClient
        do {
            client = try options.apiClient()
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }

        let notificationId = id

        do {
            printVerbose("Marking notification as read...", verbose: options.verbose)
            try runAsync {
                try await client.markNotificationRead(id: notificationId)
            }
            print("Notification \(notificationId) marked as read")
        } catch let error as CLIError {
            printError(error.localizedDescription)
            throw ExitCode(rawValue: error.exitCode)
        }
    }
}
