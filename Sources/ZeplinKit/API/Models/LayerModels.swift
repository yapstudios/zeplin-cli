import Foundation

public struct Layer: Codable, Sendable {
    public let id: String
    public let sourceId: String?
    public let type: String?
    public let name: String?
    public let rect: BoundingRect?
    public let opacity: Double?
    public let borderRadius: Double?
    public let rotation: Double?
    public let exportable: Bool?
    public let content: String?
    public let componentName: String?
    public let layers: [Layer]?
}

public struct BoundingRect: Codable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
}

public struct ScreenAsset: Codable, Sendable {
    public let layerSourceId: String?
    public let displayName: String?
    public let layerName: String?
    public let contents: [AssetContent]?
}

public struct AssetContent: Codable, Sendable {
    public let url: String?
    public let format: String?
    public let density: AssetDensity?
}

public enum AssetDensity: Codable, Sendable, CustomStringConvertible {
    case number(Double)
    case string(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let d = try? container.decode(Double.self) {
            self = .number(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else {
            throw DecodingError.typeMismatch(AssetDensity.self, .init(codingPath: decoder.codingPath, debugDescription: "Expected String or Number"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .number(let d): try container.encode(d)
        case .string(let s): try container.encode(s)
        }
    }

    public var description: String {
        switch self {
        case .number(let d):
            let i = Int(d)
            return Double(i) == d ? "\(i)x" : "\(d)x"
        case .string(let s): return s
        }
    }
}
