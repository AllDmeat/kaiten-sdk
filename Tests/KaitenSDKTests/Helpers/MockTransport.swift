import Foundation
import HTTPTypes
import OpenAPIRuntime

/// A mock client transport for testing that records all requests and returns configurable responses.
final class MockClientTransport: ClientTransport, @unchecked Sendable {

    /// A recorded request with all parameters passed to `send`.
    struct RecordedRequest: Sendable {
        let request: HTTPRequest
        let body: HTTPBody?
        let baseURL: URL
        let operationID: String
    }

    /// The closure invoked for every call to `send`.
    private let handler: @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)

    /// All requests recorded so far.
    private let _lock = NSLock()
    private var _recordedRequests: [RecordedRequest] = []

    var recordedRequests: [RecordedRequest] {
        _lock.withLock { _recordedRequests }
    }

    /// Creates a mock transport with a custom handler.
    /// - Parameter handler: A closure called for every `send` invocation.
    init(handler: @escaping @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)) {
        self.handler = handler
    }

    /// Convenience factory that always returns a fixed status code and body.
    /// - Parameters:
    ///   - statusCode: The HTTP status code to return.
    ///   - body: An optional response body string (UTF-8 encoded).
    /// - Returns: A configured `MockClientTransport`.
    static func returning(statusCode: Int, body: String? = nil) -> MockClientTransport {
        MockClientTransport { _, _, _, _ in
            var headerFields = HTTPFields()
            if body != nil {
                headerFields[.contentType] = "application/json"
            }
            let response = HTTPResponse(status: .init(code: statusCode), headerFields: headerFields)
            let responseBody: HTTPBody? = body.map { .init($0) }
            return (response, responseBody)
        }
    }

    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let recorded = RecordedRequest(request: request, body: body, baseURL: baseURL, operationID: operationID)
        _lock.withLock { _recordedRequests.append(recorded) }
        return try await handler(request, body, baseURL, operationID)
    }
}
