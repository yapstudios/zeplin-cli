import Foundation

public struct Styleguide: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let description: String?
    public let platform: String?
    public let status: String?
    public let thumbnail: String?
    public let numberOfComponents: Int?
    public let numberOfTextStyles: Int?
    public let numberOfColors: Int?
    public let numberOfSpacingTokens: Int?
    public let created: Int?
    public let updated: Int?
}

public struct StyleguideMember: Codable, Sendable {
    public let user: User?
    public let role: String?
}
