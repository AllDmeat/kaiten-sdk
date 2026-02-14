import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import KaitenSDK

@Suite("RetryMiddleware")
struct RetryMiddlewareTests {

    @Test("429 then 200 succeeds after retry")
    func retryThenSuccess() async throws {
        let middleware = RetryMiddleware(maxAttempts: 3)
        var callCount = 0

        let (response, _) = try await middleware.intercept(
            HTTPRequest(method: .get, scheme: "https", authority: "test.kaiten.ru", path: "/test"),
            body: nil,
            baseURL: URL(string: "https://test.kaiten.ru")!,
            operationID: "test"
        ) { _, _, _ in
            callCount += 1
            if callCount == 1 {
                return (HTTPResponse(status: .tooManyRequests, headerFields: HTTPFields([
                    HTTPField(name: HTTPField.Name("Retry-After")!, value: "0"),
                ])), nil)
            }
            return (HTTPResponse(status: .ok), HTTPBody("{}"))
        }

        #expect(response.status == .ok)
        #expect(callCount == 2)
    }

    @Test("429 three times throws rateLimited")
    func exhaustedRetries() async throws {
        let middleware = RetryMiddleware(maxAttempts: 3)

        await #expect(throws: KaitenError.self) {
            _ = try await middleware.intercept(
                HTTPRequest(method: .get, scheme: "https", authority: "test.kaiten.ru", path: "/test"),
                body: nil,
                baseURL: URL(string: "https://test.kaiten.ru")!,
                operationID: "test"
            ) { _, _, _ in
                (HTTPResponse(status: .tooManyRequests, headerFields: HTTPFields([
                    HTTPField(name: HTTPField.Name("Retry-After")!, value: "0"),
                ])), nil)
            }
        }
    }
}
