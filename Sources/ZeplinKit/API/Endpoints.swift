import Foundation

public enum Endpoint {
    // User
    case getCurrentUser

    // Organizations
    case listOrganizations
    case getOrganization(id: String)
    case getOrganizationBilling(organizationId: String)

    // Projects
    case listProjects(organizationId: String?, limit: Int?, offset: Int?)
    case getProject(id: String)
    case listOrganizationProjects(organizationId: String, limit: Int?, offset: Int?)

    // Screens
    case listScreens(projectId: String, sectionId: String?, limit: Int?, offset: Int?)
    case getScreen(projectId: String, screenId: String)
    case listScreenVersions(projectId: String, screenId: String, limit: Int?, offset: Int?)
    case listScreenSections(projectId: String, limit: Int?, offset: Int?)

    // Components
    case listProjectComponents(projectId: String, limit: Int?, offset: Int?)
    case getProjectComponent(projectId: String, componentId: String)
    case listStyleguideComponents(styleguideId: String, limit: Int?, offset: Int?)
    case getStyleguideComponent(styleguideId: String, componentId: String)

    // Styleguides
    case listStyleguides(limit: Int?, offset: Int?)
    case getStyleguide(id: String)

    // Colors
    case listProjectColors(projectId: String, limit: Int?, offset: Int?)
    case listStyleguideColors(styleguideId: String, limit: Int?, offset: Int?)

    // Text Styles
    case listProjectTextStyles(projectId: String, limit: Int?, offset: Int?)
    case listStyleguideTextStyles(styleguideId: String, limit: Int?, offset: Int?)

    // Spacing Tokens
    case listProjectSpacingTokens(projectId: String, limit: Int?, offset: Int?)
    case listStyleguideSpacingTokens(styleguideId: String, limit: Int?, offset: Int?)

    // Design Tokens
    case getProjectDesignTokens(projectId: String)
    case getStyleguideDesignTokens(styleguideId: String)

    // Flows
    case listFlowBoards(projectId: String, limit: Int?, offset: Int?)
    case getFlowBoard(projectId: String, boardId: String)
    case listFlowBoardNodes(projectId: String, boardId: String, limit: Int?, offset: Int?)
    case listFlowBoardConnectors(projectId: String, boardId: String, limit: Int?, offset: Int?)

    // Members
    case listOrganizationMembers(organizationId: String, limit: Int?, offset: Int?)
    case listProjectMembers(projectId: String, limit: Int?, offset: Int?)
    case listStyleguideMembers(styleguideId: String, limit: Int?, offset: Int?)
    case inviteOrganizationMember(organizationId: String)

    // Organization Webhooks
    case listOrganizationWebhooks(organizationId: String)
    case createOrganizationWebhook(organizationId: String)
    case getOrganizationWebhook(organizationId: String, webhookId: String)
    case updateOrganizationWebhook(organizationId: String, webhookId: String)
    case deleteOrganizationWebhook(organizationId: String, webhookId: String)

    // Project Webhooks
    case listProjectWebhooks(projectId: String)
    case createProjectWebhook(projectId: String)
    case getProjectWebhook(projectId: String, webhookId: String)
    case updateProjectWebhook(projectId: String, webhookId: String)
    case deleteProjectWebhook(projectId: String, webhookId: String)

    // Styleguide Webhooks
    case listStyleguideWebhooks(styleguideId: String)
    case createStyleguideWebhook(styleguideId: String)
    case getStyleguideWebhook(styleguideId: String, webhookId: String)
    case updateStyleguideWebhook(styleguideId: String, webhookId: String)
    case deleteStyleguideWebhook(styleguideId: String, webhookId: String)

    // Notifications
    case listNotifications(limit: Int?, offset: Int?)
    case getNotification(id: String)
    case markNotificationRead(id: String)
    case markNotificationsRead

    public var path: String {
        switch self {
        case .getCurrentUser:
            return "/v1/users/me"

        case .listOrganizations:
            return "/v1/organizations"
        case .getOrganization(let id):
            return "/v1/organizations/\(id)"
        case .getOrganizationBilling(let organizationId):
            return "/v1/organizations/\(organizationId)/billing"

        case .listProjects:
            return "/v1/projects"
        case .getProject(let id):
            return "/v1/projects/\(id)"
        case .listOrganizationProjects(let organizationId, _, _):
            return "/v1/organizations/\(organizationId)/projects"

        case .listScreens(let projectId, _, _, _):
            return "/v1/projects/\(projectId)/screens"
        case .getScreen(let projectId, let screenId):
            return "/v1/projects/\(projectId)/screens/\(screenId)"
        case .listScreenVersions(let projectId, let screenId, _, _):
            return "/v1/projects/\(projectId)/screens/\(screenId)/versions"
        case .listScreenSections(let projectId, _, _):
            return "/v1/projects/\(projectId)/screen_sections"

        case .listProjectComponents(let projectId, _, _):
            return "/v1/projects/\(projectId)/components"
        case .getProjectComponent(let projectId, let componentId):
            return "/v1/projects/\(projectId)/components/\(componentId)"
        case .listStyleguideComponents(let styleguideId, _, _):
            return "/v1/styleguides/\(styleguideId)/components"
        case .getStyleguideComponent(let styleguideId, let componentId):
            return "/v1/styleguides/\(styleguideId)/components/\(componentId)"

        case .listStyleguides:
            return "/v1/styleguides"
        case .getStyleguide(let id):
            return "/v1/styleguides/\(id)"

        case .listProjectColors(let projectId, _, _):
            return "/v1/projects/\(projectId)/colors"
        case .listStyleguideColors(let styleguideId, _, _):
            return "/v1/styleguides/\(styleguideId)/colors"

        case .listProjectTextStyles(let projectId, _, _):
            return "/v1/projects/\(projectId)/text_styles"
        case .listStyleguideTextStyles(let styleguideId, _, _):
            return "/v1/styleguides/\(styleguideId)/text_styles"

        case .listProjectSpacingTokens(let projectId, _, _):
            return "/v1/projects/\(projectId)/spacing_tokens"
        case .listStyleguideSpacingTokens(let styleguideId, _, _):
            return "/v1/styleguides/\(styleguideId)/spacing_tokens"

        case .getProjectDesignTokens(let projectId):
            return "/v1/projects/\(projectId)/design_tokens"
        case .getStyleguideDesignTokens(let styleguideId):
            return "/v1/styleguides/\(styleguideId)/design_tokens"

        case .listFlowBoards(let projectId, _, _):
            return "/v1/projects/\(projectId)/flow_boards"
        case .getFlowBoard(let projectId, let boardId):
            return "/v1/projects/\(projectId)/flow_boards/\(boardId)"
        case .listFlowBoardNodes(let projectId, let boardId, _, _):
            return "/v1/projects/\(projectId)/flow_boards/\(boardId)/nodes"
        case .listFlowBoardConnectors(let projectId, let boardId, _, _):
            return "/v1/projects/\(projectId)/flow_boards/\(boardId)/connectors"

        case .listOrganizationMembers(let organizationId, _, _):
            return "/v1/organizations/\(organizationId)/members"
        case .listProjectMembers(let projectId, _, _):
            return "/v1/projects/\(projectId)/members"
        case .listStyleguideMembers(let styleguideId, _, _):
            return "/v1/styleguides/\(styleguideId)/members"
        case .inviteOrganizationMember(let organizationId):
            return "/v1/organizations/\(organizationId)/members"

        case .listOrganizationWebhooks(let organizationId):
            return "/v1/organizations/\(organizationId)/webhooks"
        case .createOrganizationWebhook(let organizationId):
            return "/v1/organizations/\(organizationId)/webhooks"
        case .getOrganizationWebhook(let organizationId, let webhookId):
            return "/v1/organizations/\(organizationId)/webhooks/\(webhookId)"
        case .updateOrganizationWebhook(let organizationId, let webhookId):
            return "/v1/organizations/\(organizationId)/webhooks/\(webhookId)"
        case .deleteOrganizationWebhook(let organizationId, let webhookId):
            return "/v1/organizations/\(organizationId)/webhooks/\(webhookId)"

        case .listProjectWebhooks(let projectId):
            return "/v1/projects/\(projectId)/webhooks"
        case .createProjectWebhook(let projectId):
            return "/v1/projects/\(projectId)/webhooks"
        case .getProjectWebhook(let projectId, let webhookId):
            return "/v1/projects/\(projectId)/webhooks/\(webhookId)"
        case .updateProjectWebhook(let projectId, let webhookId):
            return "/v1/projects/\(projectId)/webhooks/\(webhookId)"
        case .deleteProjectWebhook(let projectId, let webhookId):
            return "/v1/projects/\(projectId)/webhooks/\(webhookId)"

        case .listStyleguideWebhooks(let styleguideId):
            return "/v1/styleguides/\(styleguideId)/webhooks"
        case .createStyleguideWebhook(let styleguideId):
            return "/v1/styleguides/\(styleguideId)/webhooks"
        case .getStyleguideWebhook(let styleguideId, let webhookId):
            return "/v1/styleguides/\(styleguideId)/webhooks/\(webhookId)"
        case .updateStyleguideWebhook(let styleguideId, let webhookId):
            return "/v1/styleguides/\(styleguideId)/webhooks/\(webhookId)"
        case .deleteStyleguideWebhook(let styleguideId, let webhookId):
            return "/v1/styleguides/\(styleguideId)/webhooks/\(webhookId)"

        case .listNotifications:
            return "/v1/users/me/notifications"
        case .getNotification(let id):
            return "/v1/users/me/notifications/\(id)"
        case .markNotificationRead(let id):
            return "/v1/users/me/notifications/\(id)"
        case .markNotificationsRead:
            return "/v1/users/me/notifications"
        }
    }

    public var method: String {
        switch self {
        case .createOrganizationWebhook, .createProjectWebhook, .createStyleguideWebhook,
             .inviteOrganizationMember:
            return "POST"
        case .updateOrganizationWebhook, .updateProjectWebhook, .updateStyleguideWebhook,
             .markNotificationRead, .markNotificationsRead:
            return "PATCH"
        case .deleteOrganizationWebhook, .deleteProjectWebhook, .deleteStyleguideWebhook:
            return "DELETE"
        default:
            return "GET"
        }
    }

    public var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []

        switch self {
        case .listProjects(let organizationId, let limit, let offset):
            if let organizationId { items.append(URLQueryItem(name: "workspace", value: organizationId)) }
            appendPagination(limit: limit, offset: offset, to: &items)

        case .listOrganizationProjects(_, let limit, let offset),
             .listScreenSections(_, let limit, let offset),
             .listProjectComponents(_, let limit, let offset),
             .listStyleguideComponents(_, let limit, let offset),
             .listStyleguides(let limit, let offset),
             .listProjectColors(_, let limit, let offset),
             .listStyleguideColors(_, let limit, let offset),
             .listProjectTextStyles(_, let limit, let offset),
             .listStyleguideTextStyles(_, let limit, let offset),
             .listProjectSpacingTokens(_, let limit, let offset),
             .listStyleguideSpacingTokens(_, let limit, let offset),
             .listFlowBoards(_, let limit, let offset),
             .listFlowBoardNodes(_, _, let limit, let offset),
             .listFlowBoardConnectors(_, _, let limit, let offset),
             .listOrganizationMembers(_, let limit, let offset),
             .listProjectMembers(_, let limit, let offset),
             .listStyleguideMembers(_, let limit, let offset),
             .listNotifications(let limit, let offset),
             .listScreenVersions(_, _, let limit, let offset):
            appendPagination(limit: limit, offset: offset, to: &items)

        case .listScreens(_, let sectionId, let limit, let offset):
            if let sectionId { items.append(URLQueryItem(name: "section_id", value: sectionId)) }
            appendPagination(limit: limit, offset: offset, to: &items)

        default:
            break
        }

        return items
    }

    private func appendPagination(limit: Int?, offset: Int?, to items: inout [URLQueryItem]) {
        if let limit { items.append(URLQueryItem(name: "limit", value: String(limit))) }
        if let offset { items.append(URLQueryItem(name: "offset", value: String(offset))) }
    }
}
