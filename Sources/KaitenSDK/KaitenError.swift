import Foundation

/// Errors thrown by the Kaiten SDK.
public enum KaitenError: Error, Sendable {
    /// A required configuration value is missing.
    case missingConfiguration(String)
    /// The provided URL is invalid.
    case invalidURL(String)
    /// The API returned 401 Unauthorized.
    case unauthorized
    /// The requested resource was not found.
    case notFound(resource: String, id: Int)
    /// The API rate limit has been exceeded.
    case rateLimited(retryAfter: TimeInterval?)
    /// The server returned a 5xx error.
    case serverError(statusCode: Int, body: String?)
    /// A network-level error occurred.
    case networkError(underlying: any Error)
    /// The API returned an unexpected HTTP status code.
    case unexpectedResponse(statusCode: Int)
}

// MARK: - LocalizedError

extension KaitenError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingConfiguration(let key):
            "Missing required configuration: \(key)"
        case .invalidURL(let url):
            "Invalid URL: \(url)"
        case .unauthorized:
            "Unauthorized – check your API token"
        case .notFound(let resource, let id):
            "\(resource) with id \(id) not found"
        case .rateLimited(let retryAfter):
            if let retryAfter {
                "Rate limited – retry after \(Int(retryAfter))s"
            } else {
                "Rate limited – retry later"
            }
        case .serverError(let statusCode, let body):
            "Server error \(statusCode)" + (body.map { ": \($0)" } ?? "")
        case .networkError(let underlying):
            "Network error: \(underlying.localizedDescription)"
        case .unexpectedResponse(let statusCode):
            "Unexpected HTTP response: \(statusCode)"
        }
    }
}

// MARK: - HTTP Status Code Mapping

extension KaitenError {
    /// Maps an HTTP status code (and optional response body) to a ``KaitenError``.
    ///
    /// Returns `nil` for 2xx success codes.
    public static func fromHTTPStatus(
        _ statusCode: Int,
        body: String? = nil,
        resource: String? = nil,
        resourceId: Int? = nil,
        retryAfter: TimeInterval? = nil
    ) -> KaitenError? {
        switch statusCode {
        case 200..<300:
            return nil
        case 401:
            return .unauthorized
        case 404:
            if let resource, let resourceId {
                return .notFound(resource: resource, id: resourceId)
            }
            return .unexpectedResponse(statusCode: 404)
        case 429:
            return .rateLimited(retryAfter: retryAfter)
        case 500...599:
            return .serverError(statusCode: statusCode, body: body)
        default:
            return .unexpectedResponse(statusCode: statusCode)
        }
    }
}
