import Foundation

public enum CLIError: Error, LocalizedError {
    case missingCredentials(String)
    case invalidCredentials(String)
    case configFileError(String)
    case apiError(statusCode: Int, message: String)
    case networkError(Error)
    case decodingError(Error)
    case fileNotFound(String)
    case invalidInput(String)
    case unauthorized
    case forbidden
    case notFound(String)
    case rateLimited
    case serverError(Int)

    public var errorDescription: String? {
        switch self {
        case .missingCredentials(let detail):
            return "Missing credentials: \(detail)"
        case .invalidCredentials(let detail):
            return "Invalid credentials: \(detail)"
        case .configFileError(let detail):
            return "Configuration error: \(detail)"
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidInput(let detail):
            return "Invalid input: \(detail)"
        case .unauthorized:
            return "Unauthorized: Check your API token"
        case .forbidden:
            return "Forbidden: You don't have permission for this action"
        case .notFound(let resource):
            return "Not found: \(resource)"
        case .rateLimited:
            return "Rate limited: Too many requests, please wait"
        case .serverError(let code):
            return "Server error (\(code)): Please try again later"
        }
    }

    public var exitCode: Int32 {
        switch self {
        case .missingCredentials, .invalidCredentials, .unauthorized, .forbidden:
            return 2
        case .configFileError, .fileNotFound, .invalidInput, .decodingError:
            return 1
        case .apiError, .networkError, .notFound, .rateLimited, .serverError:
            return 1
        }
    }
}
