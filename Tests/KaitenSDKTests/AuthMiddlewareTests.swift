import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import KaitenSDK

@Suite("AuthenticationMiddleware")
struct AuthMiddlewareTests {

    @Test("Adds Bearer token header")
    func addsBearer() async throws {
        let middleware = AuthenticationMiddleware(token: "my-secret-token")
        var capturedRequest: HTTPRequest?

        let _ = try await middleware.intercept(
            HTTPRequest(method: .get, scheme: "https", authority: "test.kaiten.ru", path: "/test"),
            body: nil,
            baseURL: URL(string: "https://test.kaiten.ru")!,
            operationID: "test"
        ) { request, body, baseURL in
            capturedRequest = request
            return (HTTPResponse(status: .ok), nil)
        }

        #expect(capturedRequest?.headerFields[.authorization] == "Bearer my-secret-token")
    }

    @Test("401 throws unauthorized")
    func unauthorized() async throws {
        let middleware = AuthenticationMiddleware(token: "bad-token")

        await #expect(throws: KaitenError.self) {
            _ = try await middleware.intercept(
                HTTPRequest(method: .get, scheme: "https", authority: "test.kaiten.ru", path: "/test"),
                body: nil,
                baseURL: URL(string: "https://test.kaiten.ru")!,
                operationID: "test"
            ) { _, _, _ in
                (HTTPResponse(status: .unauthorized), nil)
            }
        }
    }
}
