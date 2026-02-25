import Foundation

public struct Page: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String?
    public let type: String?
    public let description: String?
}

public struct SpacingSection: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String?
    public let description: String?
}

public struct VariableCollection: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String?
}
