import Foundation

public struct Screen: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let description: String?
    public let tags: [String]?
    public let image: ScreenImage?
    public let updated: Int?
    public let created: Int?
    public let numberOfVersions: Int?
    public let numberOfNotes: Int?
    public let section: ScreenSectionRef?
}

public struct ScreenImage: Codable, Sendable {
    public let width: Int?
    public let height: Int?
    public let originalUrl: String?
}

public struct ScreenSectionRef: Codable, Sendable {
    public let id: String
    public let name: String?
}

public struct ScreenSection: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let description: String?
}

public struct ScreenVersion: Codable, Sendable, Identifiable {
    public let id: String
    public let commit: VersionCommit?
    public let source: String?
    public let imageUrl: String?
    public let width: Int?
    public let height: Int?
    public let created: Int?
}

public struct VersionCommit: Codable, Sendable {
    public let message: String?
    public let author: String?
}
