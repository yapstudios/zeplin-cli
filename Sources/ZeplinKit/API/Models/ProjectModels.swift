import Foundation

public struct EntityReference: Codable, Sendable {
    public let id: String
    public let name: String?

    public init(id: String, name: String? = nil) {
        self.id = id
        self.name = name
    }
}

public struct Project: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let description: String?
    public let platform: String?
    public let status: String?
    public let thumbnail: String?
    public let numberOfScreens: Int?
    public let numberOfComponents: Int?
    public let numberOfConnectedComponents: Int?
    public let numberOfTextStyles: Int?
    public let numberOfColors: Int?
    public let numberOfMembers: Int?
    public let numberOfSpacingTokens: Int?
    public let organization: EntityReference?
    public let linkedStyleguide: EntityReference?
    public let workflowStatus: WorkflowStatus?
    public let created: Int?
    public let updated: Int?
}

public struct WorkflowStatus: Codable, Sendable {
    public let id: String
    public let name: String?
}

public struct ProjectMember: Codable, Sendable {
    public let user: User?
    public let role: String?
}
