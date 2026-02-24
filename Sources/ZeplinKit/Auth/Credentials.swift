import Foundation

public struct Credentials: Codable, Sendable {
    public let token: String
    public let organizationId: String?

    public init(token: String, organizationId: String? = nil) {
        self.token = token
        self.organizationId = organizationId
    }
}

public struct Profile: Codable, Sendable {
    public let token: String
    public let organizationId: String?

    public init(token: String, organizationId: String? = nil) {
        self.token = token
        self.organizationId = organizationId
    }

    public func toCredentials() -> Credentials {
        Credentials(token: token, organizationId: organizationId)
    }
}

public struct ConfigFile: Codable, Sendable {
    public var defaultProfile: String?
    public var profiles: [String: Profile]

    public init(defaultProfile: String? = nil, profiles: [String: Profile] = [:]) {
        self.defaultProfile = defaultProfile
        self.profiles = profiles
    }

    private enum CodingKeys: String, CodingKey {
        case defaultProfile = "default"
        case profiles
    }
}
