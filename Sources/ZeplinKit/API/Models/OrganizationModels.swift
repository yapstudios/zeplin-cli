import Foundation

public struct Organization: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let logo: String?
}

public struct OrganizationMember: Codable, Sendable {
    public let user: User?
    public let role: String?
    public let restricted: Bool?
}

public struct OrganizationBilling: Codable, Sendable {
    public let totalSeatCount: Int?
    public let usedSeatCount: Int?
}
