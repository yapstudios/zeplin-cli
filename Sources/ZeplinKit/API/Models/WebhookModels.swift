import Foundation

public struct Webhook: Codable, Sendable, Identifiable {
    public let id: String
    public let url: String?
    public let name: String?
    public let status: String?
    public let urlHealth: String?
    public let events: [String]?
    public let created: Int?
    public let updated: Int?
}

public struct WebhookCreateBody: Codable, Sendable {
    public let url: String
    public let events: [String]

    public init(url: String, events: [String]) {
        self.url = url
        self.events = events
    }
}

public struct WebhookUpdateBody: Codable, Sendable {
    public let url: String?
    public let events: [String]?
    public let status: String?

    public init(url: String? = nil, events: [String]? = nil, status: String? = nil) {
        self.url = url
        self.events = events
        self.status = status
    }
}

public struct UserWebhook: Codable, Sendable, Identifiable {
    public let id: String
    public let url: String?
    public let status: String?
    public let events: [String]?
    public let created: Int?
    public let updated: Int?
}
