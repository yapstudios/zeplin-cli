import Foundation

public struct User: Codable, Sendable, Identifiable {
    public let id: String
    public let email: String?
    public let username: String?
    public let emotar: String?
    public let avatar: String?
}

public struct ZeplinNotification: Codable, Sendable, Identifiable {
    public let id: String
    public let type: String?
    public let isRead: Bool?
    public let action: String?
    public let created: Int?
    public let updated: Int?
    public let actor: NotificationActor?
    public let resource: NotificationResource?
}

public struct NotificationActor: Codable, Sendable {
    public let user: User?
}

public struct NotificationResource: Codable, Sendable {
    public let id: String?
    public let type: String?
}
