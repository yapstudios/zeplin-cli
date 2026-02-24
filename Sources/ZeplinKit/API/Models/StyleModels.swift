import Foundation

public struct Color: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String?
    public let r: Int
    public let g: Int
    public let b: Int
    public let a: Double
    public let created: Int?
}

public struct TextStyle: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String?
    public let created: Int?
    public let postscriptName: String?
    public let fontFamily: String?
    public let fontSize: Double?
    public let fontWeight: Int?
    public let fontStyle: String?
    public let fontStretch: String?
    public let lineHeight: Double?
    public let letterSpacing: Double?
    public let textAlign: String?
    public let color: ColorData?
}

public struct ColorData: Codable, Sendable {
    public let r: Int?
    public let g: Int?
    public let b: Int?
    public let a: Double?
}

public struct SpacingToken: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String?
    public let value: Double?
    public let created: Int?
}
