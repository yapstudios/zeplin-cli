import Foundation

public struct APIErrorResponse: Codable, Sendable {
    public let message: String?
    public let detail: String?
    public let code: String?
}
