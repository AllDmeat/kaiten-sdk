import Foundation
import HTTPTypes
import OpenAPIRuntime

/// A middleware that injects a Bearer token into every outgoing request
/// and throws ``KaitenError/unauthorized`` on 401 responses.
struct AuthenticationMiddleware: ClientMiddleware {
    private let token: String

    init(token: String) {
        self.token = token
    }

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        request.headerFields[.authorization] = "Bearer \(token)"

        let (response, responseBody) = try await next(request, body, baseURL)

        if response.status == .unauthorized {
            throw KaitenError.unauthorized
        }

        return (response, responseBody)
    }
}
