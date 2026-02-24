import Foundation

public struct FlowBoard: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let numberOfConnectors: Int?
    public let numberOfNodes: Int?
    public let numberOfGroups: Int?
    public let created: Int?
    public let updated: Int?
}

public struct FlowBoardNode: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String?
    public let created: Int?
}

public struct FlowBoardConnector: Codable, Sendable, Identifiable {
    public let id: String
    public let label: String?
    public let created: Int?
}

public struct FlowBoardGroup: Codable, Sendable {
    public let id: String
    public let name: String?
    public let created: Int?
}
