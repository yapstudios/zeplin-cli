import Foundation

public struct Component: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let description: String?
    public let image: ScreenImage?
    public let created: Int?
    public let updated: Int?
    public let section: ComponentSectionRef?
}

public struct ComponentSectionRef: Codable, Sendable {
    public let id: String
    public let name: String?
}

public struct ComponentSection: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
}

public struct ComponentVersion: Codable, Sendable {
    public let id: String
    public let commit: VersionCommit?
    public let created: Int?
}

public struct ConnectedComponent: Codable, Sendable {
    public let name: String?
    public let description: String?
    public let filePath: String?
    public let components: [EntityReference]?
}
