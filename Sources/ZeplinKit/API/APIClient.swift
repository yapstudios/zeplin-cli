import Foundation

public actor APIClient {
    private let authProvider: AuthProvider
    private let baseURL = URL(string: "https://api.zeplin.dev")!
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(credentials: Credentials) {
        self.authProvider = AuthProvider(credentials: credentials)
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder
    }

    // MARK: - Core Request Methods

    private func buildRequest(endpoint: Endpoint, body: Data? = nil) async -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)!
        let queryItems = endpoint.queryItems
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = endpoint.method
        request.setValue("Bearer \(await authProvider.getToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }

    private func execute(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw CLIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CLIError.networkError(URLError(.badServerResponse))
        }

        return (data, httpResponse)
    }

    private func handleResponse(data: Data, response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw CLIError.unauthorized
        case 403:
            throw CLIError.forbidden
        case 404:
            throw CLIError.notFound("Resource not found")
        case 429:
            throw CLIError.rateLimited
        case 500...599:
            throw CLIError.serverError(response.statusCode)
        default:
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                let message = errorResponse.message ?? errorResponse.detail ?? "Unknown error"
                throw CLIError.apiError(statusCode: response.statusCode, message: message)
            }
            throw CLIError.apiError(statusCode: response.statusCode, message: "Unknown error")
        }
    }

    public func request<T: Codable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        let urlRequest = await buildRequest(endpoint: endpoint)
        let (data, response) = try await execute(urlRequest)
        try handleResponse(data: data, response: response)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw CLIError.decodingError(error)
        }
    }

    public func requestVoid(_ endpoint: Endpoint) async throws {
        let urlRequest = await buildRequest(endpoint: endpoint)
        let (data, response) = try await execute(urlRequest)
        try handleResponse(data: data, response: response)
    }

    public func requestRawData(_ endpoint: Endpoint) async throws -> Data {
        let urlRequest = await buildRequest(endpoint: endpoint)
        let (data, response) = try await execute(urlRequest)
        try handleResponse(data: data, response: response)
        return data
    }

    public func requestWithBody<B: Encodable & Sendable, T: Codable & Sendable>(
        _ endpoint: Endpoint,
        body: B
    ) async throws -> T {
        let bodyData = try encoder.encode(body)
        let urlRequest = await buildRequest(endpoint: endpoint, body: bodyData)
        let (data, response) = try await execute(urlRequest)
        try handleResponse(data: data, response: response)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw CLIError.decodingError(error)
        }
    }

    public func requestWithBodyVoid<B: Encodable & Sendable>(
        _ endpoint: Endpoint,
        body: B
    ) async throws {
        let bodyData = try encoder.encode(body)
        let urlRequest = await buildRequest(endpoint: endpoint, body: bodyData)
        let (data, response) = try await execute(urlRequest)
        try handleResponse(data: data, response: response)
    }

    // MARK: - Pagination

    public func paginateAll<T: Codable & Sendable>(
        pageSize: Int = 100,
        fetch: @Sendable (Int, Int) async throws -> [T]
    ) async throws -> [T] {
        var all: [T] = []
        var offset = 0
        while true {
            let page = try await fetch(pageSize, offset)
            all.append(contentsOf: page)
            if page.count < pageSize { break }
            offset += pageSize
        }
        return all
    }

    // MARK: - User

    public func getCurrentUser() async throws -> User {
        try await request(.getCurrentUser)
    }

    // MARK: - Organizations

    public func listOrganizations() async throws -> [Organization] {
        try await request(.listOrganizations)
    }

    public func getOrganization(id: String) async throws -> Organization {
        try await request(.getOrganization(id: id))
    }

    public func getOrganizationBilling(organizationId: String) async throws -> OrganizationBilling {
        try await request(.getOrganizationBilling(organizationId: organizationId))
    }

    // MARK: - Projects

    public func listProjects(organizationId: String? = nil, limit: Int? = nil, offset: Int? = nil) async throws -> [Project] {
        try await request(.listProjects(organizationId: organizationId, limit: limit, offset: offset))
    }

    public func getProject(id: String) async throws -> Project {
        try await request(.getProject(id: id))
    }

    public func listOrganizationProjects(organizationId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [Project] {
        try await request(.listOrganizationProjects(organizationId: organizationId, limit: limit, offset: offset))
    }

    public func listAllProjects(organizationId: String? = nil) async throws -> [Project] {
        try await paginateAll { limit, offset in
            try await self.listProjects(organizationId: organizationId, limit: limit, offset: offset)
        }
    }

    // MARK: - Screens

    public func listScreens(projectId: String, sectionId: String? = nil, limit: Int? = nil, offset: Int? = nil) async throws -> [Screen] {
        try await request(.listScreens(projectId: projectId, sectionId: sectionId, limit: limit, offset: offset))
    }

    public func getScreen(projectId: String, screenId: String) async throws -> Screen {
        try await request(.getScreen(projectId: projectId, screenId: screenId))
    }

    public func listScreenVersions(projectId: String, screenId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [ScreenVersion] {
        try await request(.listScreenVersions(projectId: projectId, screenId: screenId, limit: limit, offset: offset))
    }

    public func listScreenSections(projectId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [ScreenSection] {
        try await request(.listScreenSections(projectId: projectId, limit: limit, offset: offset))
    }

    public func listAllScreens(projectId: String, sectionId: String? = nil) async throws -> [Screen] {
        try await paginateAll { limit, offset in
            try await self.listScreens(projectId: projectId, sectionId: sectionId, limit: limit, offset: offset)
        }
    }

    public func listAllScreenVersions(projectId: String, screenId: String) async throws -> [ScreenVersion] {
        try await paginateAll { limit, offset in
            try await self.listScreenVersions(projectId: projectId, screenId: screenId, limit: limit, offset: offset)
        }
    }

    public func listAllScreenSections(projectId: String) async throws -> [ScreenSection] {
        try await paginateAll { limit, offset in
            try await self.listScreenSections(projectId: projectId, limit: limit, offset: offset)
        }
    }

    // MARK: - Components

    public func listProjectComponents(projectId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [Component] {
        try await request(.listProjectComponents(projectId: projectId, limit: limit, offset: offset))
    }

    public func getProjectComponent(projectId: String, componentId: String) async throws -> Component {
        try await request(.getProjectComponent(projectId: projectId, componentId: componentId))
    }

    public func listStyleguideComponents(styleguideId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [Component] {
        try await request(.listStyleguideComponents(styleguideId: styleguideId, limit: limit, offset: offset))
    }

    public func getStyleguideComponent(styleguideId: String, componentId: String) async throws -> Component {
        try await request(.getStyleguideComponent(styleguideId: styleguideId, componentId: componentId))
    }

    public func listAllProjectComponents(projectId: String) async throws -> [Component] {
        try await paginateAll { limit, offset in
            try await self.listProjectComponents(projectId: projectId, limit: limit, offset: offset)
        }
    }

    public func listAllStyleguideComponents(styleguideId: String) async throws -> [Component] {
        try await paginateAll { limit, offset in
            try await self.listStyleguideComponents(styleguideId: styleguideId, limit: limit, offset: offset)
        }
    }

    // MARK: - Styleguides

    public func listStyleguides(limit: Int? = nil, offset: Int? = nil) async throws -> [Styleguide] {
        try await request(.listStyleguides(limit: limit, offset: offset))
    }

    public func getStyleguide(id: String) async throws -> Styleguide {
        try await request(.getStyleguide(id: id))
    }

    public func listAllStyleguides() async throws -> [Styleguide] {
        try await paginateAll { limit, offset in
            try await self.listStyleguides(limit: limit, offset: offset)
        }
    }

    // MARK: - Colors

    public func listProjectColors(projectId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [Color] {
        try await request(.listProjectColors(projectId: projectId, limit: limit, offset: offset))
    }

    public func listStyleguideColors(styleguideId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [Color] {
        try await request(.listStyleguideColors(styleguideId: styleguideId, limit: limit, offset: offset))
    }

    public func listAllProjectColors(projectId: String) async throws -> [Color] {
        try await paginateAll { limit, offset in
            try await self.listProjectColors(projectId: projectId, limit: limit, offset: offset)
        }
    }

    public func listAllStyleguideColors(styleguideId: String) async throws -> [Color] {
        try await paginateAll { limit, offset in
            try await self.listStyleguideColors(styleguideId: styleguideId, limit: limit, offset: offset)
        }
    }

    // MARK: - Text Styles

    public func listProjectTextStyles(projectId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [TextStyle] {
        try await request(.listProjectTextStyles(projectId: projectId, limit: limit, offset: offset))
    }

    public func listStyleguideTextStyles(styleguideId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [TextStyle] {
        try await request(.listStyleguideTextStyles(styleguideId: styleguideId, limit: limit, offset: offset))
    }

    public func listAllProjectTextStyles(projectId: String) async throws -> [TextStyle] {
        try await paginateAll { limit, offset in
            try await self.listProjectTextStyles(projectId: projectId, limit: limit, offset: offset)
        }
    }

    public func listAllStyleguideTextStyles(styleguideId: String) async throws -> [TextStyle] {
        try await paginateAll { limit, offset in
            try await self.listStyleguideTextStyles(styleguideId: styleguideId, limit: limit, offset: offset)
        }
    }

    // MARK: - Spacing Tokens

    public func listProjectSpacingTokens(projectId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [SpacingToken] {
        try await request(.listProjectSpacingTokens(projectId: projectId, limit: limit, offset: offset))
    }

    public func listStyleguideSpacingTokens(styleguideId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [SpacingToken] {
        try await request(.listStyleguideSpacingTokens(styleguideId: styleguideId, limit: limit, offset: offset))
    }

    public func listAllProjectSpacingTokens(projectId: String) async throws -> [SpacingToken] {
        try await paginateAll { limit, offset in
            try await self.listProjectSpacingTokens(projectId: projectId, limit: limit, offset: offset)
        }
    }

    public func listAllStyleguideSpacingTokens(styleguideId: String) async throws -> [SpacingToken] {
        try await paginateAll { limit, offset in
            try await self.listStyleguideSpacingTokens(styleguideId: styleguideId, limit: limit, offset: offset)
        }
    }

    // MARK: - Design Tokens

    public func getProjectDesignTokens(projectId: String) async throws -> Data {
        try await requestRawData(.getProjectDesignTokens(projectId: projectId))
    }

    public func getStyleguideDesignTokens(styleguideId: String) async throws -> Data {
        try await requestRawData(.getStyleguideDesignTokens(styleguideId: styleguideId))
    }

    // MARK: - Flows

    public func listFlowBoards(projectId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [FlowBoard] {
        try await request(.listFlowBoards(projectId: projectId, limit: limit, offset: offset))
    }

    public func getFlowBoard(projectId: String, boardId: String) async throws -> FlowBoard {
        try await request(.getFlowBoard(projectId: projectId, boardId: boardId))
    }

    public func listFlowBoardNodes(projectId: String, boardId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [FlowBoardNode] {
        try await request(.listFlowBoardNodes(projectId: projectId, boardId: boardId, limit: limit, offset: offset))
    }

    public func listFlowBoardConnectors(projectId: String, boardId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [FlowBoardConnector] {
        try await request(.listFlowBoardConnectors(projectId: projectId, boardId: boardId, limit: limit, offset: offset))
    }

    public func listAllFlowBoards(projectId: String) async throws -> [FlowBoard] {
        try await paginateAll { limit, offset in
            try await self.listFlowBoards(projectId: projectId, limit: limit, offset: offset)
        }
    }

    public func listAllFlowBoardNodes(projectId: String, boardId: String) async throws -> [FlowBoardNode] {
        try await paginateAll { limit, offset in
            try await self.listFlowBoardNodes(projectId: projectId, boardId: boardId, limit: limit, offset: offset)
        }
    }

    public func listAllFlowBoardConnectors(projectId: String, boardId: String) async throws -> [FlowBoardConnector] {
        try await paginateAll { limit, offset in
            try await self.listFlowBoardConnectors(projectId: projectId, boardId: boardId, limit: limit, offset: offset)
        }
    }

    // MARK: - Members

    public func listOrganizationMembers(organizationId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [OrganizationMember] {
        try await request(.listOrganizationMembers(organizationId: organizationId, limit: limit, offset: offset))
    }

    public func listProjectMembers(projectId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [ProjectMember] {
        try await request(.listProjectMembers(projectId: projectId, limit: limit, offset: offset))
    }

    public func listStyleguideMembers(styleguideId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [StyleguideMember] {
        try await request(.listStyleguideMembers(styleguideId: styleguideId, limit: limit, offset: offset))
    }

    public func listAllOrganizationMembers(organizationId: String) async throws -> [OrganizationMember] {
        try await paginateAll { limit, offset in
            try await self.listOrganizationMembers(organizationId: organizationId, limit: limit, offset: offset)
        }
    }

    public func listAllProjectMembers(projectId: String) async throws -> [ProjectMember] {
        try await paginateAll { limit, offset in
            try await self.listProjectMembers(projectId: projectId, limit: limit, offset: offset)
        }
    }

    public func listAllStyleguideMembers(styleguideId: String) async throws -> [StyleguideMember] {
        try await paginateAll { limit, offset in
            try await self.listStyleguideMembers(styleguideId: styleguideId, limit: limit, offset: offset)
        }
    }

    public func inviteOrganizationMember<B: Encodable & Sendable>(organizationId: String, body: B) async throws {
        try await requestWithBodyVoid(.inviteOrganizationMember(organizationId: organizationId), body: body)
    }

    // MARK: - Webhooks (Organization)

    public func listOrganizationWebhooks(organizationId: String) async throws -> [Webhook] {
        try await request(.listOrganizationWebhooks(organizationId: organizationId))
    }

    public func createOrganizationWebhook(organizationId: String, body: WebhookCreateBody) async throws -> Webhook {
        try await requestWithBody(.createOrganizationWebhook(organizationId: organizationId), body: body)
    }

    public func getOrganizationWebhook(organizationId: String, webhookId: String) async throws -> Webhook {
        try await request(.getOrganizationWebhook(organizationId: organizationId, webhookId: webhookId))
    }

    public func updateOrganizationWebhook(organizationId: String, webhookId: String, body: WebhookUpdateBody) async throws -> Webhook {
        try await requestWithBody(.updateOrganizationWebhook(organizationId: organizationId, webhookId: webhookId), body: body)
    }

    public func deleteOrganizationWebhook(organizationId: String, webhookId: String) async throws {
        try await requestVoid(.deleteOrganizationWebhook(organizationId: organizationId, webhookId: webhookId))
    }

    // MARK: - Webhooks (Project)

    public func listProjectWebhooks(projectId: String) async throws -> [Webhook] {
        try await request(.listProjectWebhooks(projectId: projectId))
    }

    public func createProjectWebhook(projectId: String, body: WebhookCreateBody) async throws -> Webhook {
        try await requestWithBody(.createProjectWebhook(projectId: projectId), body: body)
    }

    public func getProjectWebhook(projectId: String, webhookId: String) async throws -> Webhook {
        try await request(.getProjectWebhook(projectId: projectId, webhookId: webhookId))
    }

    public func updateProjectWebhook(projectId: String, webhookId: String, body: WebhookUpdateBody) async throws -> Webhook {
        try await requestWithBody(.updateProjectWebhook(projectId: projectId, webhookId: webhookId), body: body)
    }

    public func deleteProjectWebhook(projectId: String, webhookId: String) async throws {
        try await requestVoid(.deleteProjectWebhook(projectId: projectId, webhookId: webhookId))
    }

    // MARK: - Webhooks (Styleguide)

    public func listStyleguideWebhooks(styleguideId: String) async throws -> [Webhook] {
        try await request(.listStyleguideWebhooks(styleguideId: styleguideId))
    }

    public func createStyleguideWebhook(styleguideId: String, body: WebhookCreateBody) async throws -> Webhook {
        try await requestWithBody(.createStyleguideWebhook(styleguideId: styleguideId), body: body)
    }

    public func getStyleguideWebhook(styleguideId: String, webhookId: String) async throws -> Webhook {
        try await request(.getStyleguideWebhook(styleguideId: styleguideId, webhookId: webhookId))
    }

    public func updateStyleguideWebhook(styleguideId: String, webhookId: String, body: WebhookUpdateBody) async throws -> Webhook {
        try await requestWithBody(.updateStyleguideWebhook(styleguideId: styleguideId, webhookId: webhookId), body: body)
    }

    public func deleteStyleguideWebhook(styleguideId: String, webhookId: String) async throws {
        try await requestVoid(.deleteStyleguideWebhook(styleguideId: styleguideId, webhookId: webhookId))
    }

    // MARK: - Notifications

    public func listNotifications(limit: Int? = nil, offset: Int? = nil) async throws -> [ZeplinNotification] {
        try await request(.listNotifications(limit: limit, offset: offset))
    }

    public func getNotification(id: String) async throws -> ZeplinNotification {
        try await request(.getNotification(id: id))
    }

    public func markNotificationRead(id: String) async throws {
        try await requestVoid(.markNotificationRead(id: id))
    }

    public func markNotificationsRead() async throws {
        try await requestVoid(.markNotificationsRead)
    }

    public func listAllNotifications() async throws -> [ZeplinNotification] {
        try await paginateAll { limit, offset in
            try await self.listNotifications(limit: limit, offset: offset)
        }
    }
}
