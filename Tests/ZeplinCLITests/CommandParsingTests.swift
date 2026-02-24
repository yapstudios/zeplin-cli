import Testing
import ArgumentParser
@testable import ZeplinCLI
@testable import ZeplinKit

@Suite("Command Parsing")
struct CommandParsingTests {

    // MARK: - Auth

    @Test func parsesAuthInit() throws {
        let command = try Zeplin.parseAsRoot(["auth", "init", "--profile", "work", "--force"])
        let cmd = try #require(command as? AuthInitCommand)
        #expect(cmd.profile == "work")
        #expect(cmd.force == true)
    }

    @Test func parsesAuthInitDefaults() throws {
        let command = try Zeplin.parseAsRoot(["auth", "init"])
        let cmd = try #require(command as? AuthInitCommand)
        #expect(cmd.profile == "default")
        #expect(cmd.force == false)
    }

    @Test func parsesAuthCheck() throws {
        let command = try Zeplin.parseAsRoot(["auth", "check"])
        #expect(command is AuthCheckCommand)
    }

    @Test func parsesAuthProfiles() throws {
        let command = try Zeplin.parseAsRoot(["auth", "profiles"])
        #expect(command is AuthProfilesCommand)
    }

    @Test func parsesAuthUse() throws {
        let command = try Zeplin.parseAsRoot(["auth", "use", "staging"])
        let cmd = try #require(command as? AuthUseCommand)
        #expect(cmd.profile == "staging")
    }

    @Test func parsesAuthUseLocal() throws {
        let command = try Zeplin.parseAsRoot(["auth", "use", "dev", "--local"])
        let cmd = try #require(command as? AuthUseCommand)
        #expect(cmd.profile == "dev")
        #expect(cmd.local == true)
    }

    // MARK: - Organizations

    @Test func parsesOrganizationsList() throws {
        let command = try Zeplin.parseAsRoot(["organizations", "list"])
        #expect(command is OrganizationsListCommand)
    }

    @Test func parsesOrganizationsGet() throws {
        let command = try Zeplin.parseAsRoot(["organizations", "get", "org123"])
        let cmd = try #require(command as? OrganizationsGetCommand)
        #expect(cmd.id == "org123")
    }

    // MARK: - Projects

    @Test func parsesProjectsList() throws {
        let command = try Zeplin.parseAsRoot(["projects", "list", "--org-id", "abc123", "-o", "table"])
        let cmd = try #require(command as? ProjectsListCommand)
        #expect(cmd.orgId == "abc123")
        #expect(cmd.options.output == .table)
    }

    @Test func parsesProjectsListWithFilters() throws {
        let command = try Zeplin.parseAsRoot(["projects", "list", "--status", "active", "--name", "Mobile", "--limit", "10", "--all"])
        let cmd = try #require(command as? ProjectsListCommand)
        #expect(cmd.status == "active")
        #expect(cmd.name == "Mobile")
        #expect(cmd.limit == 10)
        #expect(cmd.all == true)
    }

    @Test func parsesProjectsGet() throws {
        let command = try Zeplin.parseAsRoot(["projects", "get", "proj456"])
        let cmd = try #require(command as? ProjectsGetCommand)
        #expect(cmd.id == "proj456")
    }

    // MARK: - Screens

    @Test func parsesScreensList() throws {
        let command = try Zeplin.parseAsRoot(["screens", "list", "proj123"])
        let cmd = try #require(command as? ScreensListCommand)
        #expect(cmd.projectId == "proj123")
    }

    @Test func parsesScreensListWithFilters() throws {
        let command = try Zeplin.parseAsRoot(["screens", "list", "proj123", "--section", "sec1", "--name", "Login", "--tag", "auth"])
        let cmd = try #require(command as? ScreensListCommand)
        #expect(cmd.section == "sec1")
        #expect(cmd.name == "Login")
        #expect(cmd.tag == "auth")
    }

    @Test func parsesScreensGet() throws {
        let command = try Zeplin.parseAsRoot(["screens", "get", "proj123", "scr456"])
        let cmd = try #require(command as? ScreensGetCommand)
        #expect(cmd.projectId == "proj123")
        #expect(cmd.screenId == "scr456")
    }

    @Test func parsesScreensVersions() throws {
        let command = try Zeplin.parseAsRoot(["screens", "versions", "proj123", "scr456"])
        let cmd = try #require(command as? ScreensVersionsCommand)
        #expect(cmd.projectId == "proj123")
        #expect(cmd.screenId == "scr456")
    }

    // MARK: - Components

    @Test func parsesComponentsList() throws {
        let command = try Zeplin.parseAsRoot(["components", "list", "--project", "p1"])
        let cmd = try #require(command as? ComponentsListCommand)
        #expect(cmd.project == "p1")
    }

    @Test func parsesComponentsListStyleguide() throws {
        let command = try Zeplin.parseAsRoot(["components", "list", "--styleguide", "sg1"])
        let cmd = try #require(command as? ComponentsListCommand)
        #expect(cmd.styleguide == "sg1")
    }

    @Test func parsesComponentsGet() throws {
        let command = try Zeplin.parseAsRoot(["components", "get", "comp001", "--project", "p1"])
        let cmd = try #require(command as? ComponentsGetCommand)
        #expect(cmd.id == "comp001")
        #expect(cmd.project == "p1")
    }

    // MARK: - Styleguides

    @Test func parsesStyleguidesList() throws {
        let command = try Zeplin.parseAsRoot(["styleguides", "list"])
        #expect(command is StyleguidesListCommand)
    }

    @Test func parsesStyleguidesGet() throws {
        let command = try Zeplin.parseAsRoot(["styleguides", "get", "sg123"])
        let cmd = try #require(command as? StyleguidesGetCommand)
        #expect(cmd.id == "sg123")
    }

    // MARK: - Colors

    @Test func parsesColorsList() throws {
        let command = try Zeplin.parseAsRoot(["colors", "list", "--project", "p1"])
        let cmd = try #require(command as? ColorsListCommand)
        #expect(cmd.project == "p1")
    }

    @Test func parsesColorsListStyleguide() throws {
        let command = try Zeplin.parseAsRoot(["colors", "list", "--styleguide", "sg1"])
        let cmd = try #require(command as? ColorsListCommand)
        #expect(cmd.styleguide == "sg1")
    }

    // MARK: - Text Styles

    @Test func parsesTextStylesList() throws {
        let command = try Zeplin.parseAsRoot(["text-styles", "list", "--project", "p1"])
        let cmd = try #require(command as? TextStylesListCommand)
        #expect(cmd.project == "p1")
    }

    // MARK: - Spacing

    @Test func parsesSpacingList() throws {
        let command = try Zeplin.parseAsRoot(["spacing", "list", "--project", "p1"])
        let cmd = try #require(command as? SpacingListCommand)
        #expect(cmd.project == "p1")
    }

    // MARK: - Design Tokens

    @Test func parsesDesignTokensGet() throws {
        let command = try Zeplin.parseAsRoot(["design-tokens", "get", "--project", "p1"])
        let cmd = try #require(command as? DesignTokensGetCommand)
        #expect(cmd.project == "p1")
    }

    @Test func parsesDesignTokensGetPretty() throws {
        let command = try Zeplin.parseAsRoot(["design-tokens", "get", "--styleguide", "sg1", "--pretty"])
        let cmd = try #require(command as? DesignTokensGetCommand)
        #expect(cmd.styleguide == "sg1")
        #expect(cmd.options.pretty == true)
    }

    // MARK: - Flows

    @Test func parsesFlowsList() throws {
        let command = try Zeplin.parseAsRoot(["flows", "list", "proj123"])
        let cmd = try #require(command as? FlowsListCommand)
        #expect(cmd.projectId == "proj123")
    }

    @Test func parsesFlowsGet() throws {
        let command = try Zeplin.parseAsRoot(["flows", "get", "proj123", "board456"])
        let cmd = try #require(command as? FlowsGetCommand)
        #expect(cmd.projectId == "proj123")
        #expect(cmd.boardId == "board456")
    }

    @Test func parsesFlowsNodes() throws {
        let command = try Zeplin.parseAsRoot(["flows", "nodes", "proj123", "board456"])
        let cmd = try #require(command as? FlowsNodesCommand)
        #expect(cmd.projectId == "proj123")
        #expect(cmd.boardId == "board456")
    }

    @Test func parsesFlowsConnectors() throws {
        let command = try Zeplin.parseAsRoot(["flows", "connectors", "proj123", "board456"])
        let cmd = try #require(command as? FlowsConnectorsCommand)
        #expect(cmd.projectId == "proj123")
        #expect(cmd.boardId == "board456")
    }

    // MARK: - Members

    @Test func parsesMembersList() throws {
        let command = try Zeplin.parseAsRoot(["members", "list", "--org-id", "org1"])
        let cmd = try #require(command as? MembersListCommand)
        #expect(cmd.orgId == "org1")
    }

    @Test func parsesMembersListProject() throws {
        let command = try Zeplin.parseAsRoot(["members", "list", "--project", "p1"])
        let cmd = try #require(command as? MembersListCommand)
        #expect(cmd.project == "p1")
    }

    @Test func parsesMembersInvite() throws {
        let command = try Zeplin.parseAsRoot(["members", "invite", "org1", "--email", "user@example.com", "--role", "editor"])
        let cmd = try #require(command as? MembersInviteCommand)
        #expect(cmd.organizationId == "org1")
        #expect(cmd.email == "user@example.com")
        #expect(cmd.role == "editor")
    }

    @Test func parsesMembersInviteDefaultRole() throws {
        let command = try Zeplin.parseAsRoot(["members", "invite", "org1", "--email", "user@example.com"])
        let cmd = try #require(command as? MembersInviteCommand)
        #expect(cmd.role == "member")
    }

    // MARK: - Webhooks

    @Test func parsesWebhooksList() throws {
        let command = try Zeplin.parseAsRoot(["webhooks", "list", "--project", "p1"])
        let cmd = try #require(command as? WebhooksListCommand)
        #expect(cmd.project == "p1")
    }

    @Test func parsesWebhooksCreate() throws {
        let command = try Zeplin.parseAsRoot(["webhooks", "create", "--project", "p1", "--url", "https://hook.example.com", "--events", "project.screen,project.color"])
        let cmd = try #require(command as? WebhooksCreateCommand)
        #expect(cmd.project == "p1")
        #expect(cmd.url == "https://hook.example.com")
        #expect(cmd.events == "project.screen,project.color")
    }

    @Test func parsesWebhooksDelete() throws {
        let command = try Zeplin.parseAsRoot(["webhooks", "delete", "wh001", "--project", "p1"])
        let cmd = try #require(command as? WebhooksDeleteCommand)
        #expect(cmd.id == "wh001")
        #expect(cmd.project == "p1")
    }

    @Test func parsesWebhooksGet() throws {
        let command = try Zeplin.parseAsRoot(["webhooks", "get", "wh001", "--org-id", "org1"])
        let cmd = try #require(command as? WebhooksGetCommand)
        #expect(cmd.id == "wh001")
        #expect(cmd.orgId == "org1")
    }

    // MARK: - Notifications

    @Test func parsesNotificationsList() throws {
        let command = try Zeplin.parseAsRoot(["notifications", "list"])
        #expect(command is NotificationsListCommand)
    }

    @Test func parsesNotificationsListUnread() throws {
        let command = try Zeplin.parseAsRoot(["notifications", "list", "--unread"])
        let cmd = try #require(command as? NotificationsListCommand)
        #expect(cmd.unread == true)
    }

    @Test func parsesNotificationsRead() throws {
        let command = try Zeplin.parseAsRoot(["notifications", "read", "notif001"])
        let cmd = try #require(command as? NotificationsReadCommand)
        #expect(cmd.id == "notif001")
    }

    // MARK: - User

    @Test func parsesUser() throws {
        let command = try Zeplin.parseAsRoot(["user"])
        #expect(command is UserCommand)
    }

    // MARK: - Global Options

    @Test func parsesOutputFormat() throws {
        let command = try Zeplin.parseAsRoot(["organizations", "list", "-o", "csv"])
        let cmd = try #require(command as? OrganizationsListCommand)
        #expect(cmd.options.output == .csv)
    }

    @Test func parsesVerboseFlag() throws {
        let command = try Zeplin.parseAsRoot(["user", "-v"])
        let cmd = try #require(command as? UserCommand)
        #expect(cmd.options.verbose == true)
    }

    @Test func parsesTokenOption() throws {
        let command = try Zeplin.parseAsRoot(["user", "--token", "my_secret_token"])
        let cmd = try #require(command as? UserCommand)
        #expect(cmd.options.token == "my_secret_token")
    }

    @Test func parsesPrettyFlag() throws {
        let command = try Zeplin.parseAsRoot(["user", "--pretty"])
        let cmd = try #require(command as? UserCommand)
        #expect(cmd.options.pretty == true)
    }

    @Test func parsesNoColorFlag() throws {
        let command = try Zeplin.parseAsRoot(["user", "--no-color"])
        let cmd = try #require(command as? UserCommand)
        #expect(cmd.options.noColor == true)
    }

    @Test func parsesQuietFlag() throws {
        let command = try Zeplin.parseAsRoot(["user", "-q"])
        let cmd = try #require(command as? UserCommand)
        #expect(cmd.options.quiet == true)
    }

    @Test func parsesProfileOption() throws {
        let command = try Zeplin.parseAsRoot(["user", "--profile", "staging"])
        let cmd = try #require(command as? UserCommand)
        #expect(cmd.options.profile == "staging")
    }

    @Test func parsesOrganizationOption() throws {
        let command = try Zeplin.parseAsRoot(["projects", "list", "--organization", "org123"])
        let cmd = try #require(command as? ProjectsListCommand)
        #expect(cmd.options.organization == "org123")
    }

    // MARK: - Error Cases

    @Test func invalidSubcommandFails() {
        #expect(throws: (any Error).self) {
            _ = try Zeplin.parseAsRoot(["nonexistent"])
        }
    }

    @Test func missingRequiredArgFails() {
        #expect(throws: (any Error).self) {
            _ = try Zeplin.parseAsRoot(["screens", "get", "proj123"])
        }
    }
}
