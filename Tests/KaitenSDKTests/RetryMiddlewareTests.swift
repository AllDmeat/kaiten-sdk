import Foundation
import HTTPTypes
import OpenAPIRuntime
import Synchronization
import Testing

@testable import KaitenSDK

@Suite("RetryMiddleware")
struct RetryMiddlewareTests {
  private enum NonTransientError: Error {
    case failed
  }

  @Test("429 then 200 succeeds after retry")
  func retryThenSuccess() async throws {
    let middleware = RetryMiddleware(maxAttempts: 3, baseDelay: 0.01)
    let callCount = Mutex(0)

    let (response, _) = try await middleware.intercept(
      HTTPRequest(method: .get, scheme: "https", authority: "test.kaiten.ru", path: "/test"),
      body: nil,
      baseURL: URL(string: "https://test.kaiten.ru")!,
      operationID: "test"
    ) { _, _, _ in
      let count = callCount.withLock { val in
        val += 1
        return val
      }
      if count == 1 {
        return (
          HTTPResponse(
            status: .tooManyRequests,
            headerFields: HTTPFields([
              HTTPField(name: HTTPField.Name("Retry-After")!, value: "0")
            ])), nil
        )
      }
      return (HTTPResponse(status: .ok), HTTPBody("{}"))
    }

    #expect(response.status == .ok)
    #expect(callCount.withLock { $0 } == 2)
  }

  @Test("429 three times throws rateLimited")
  func exhaustedRetries() async throws {
    let middleware = RetryMiddleware(maxAttempts: 3, baseDelay: 0.01)

    await #expect(throws: KaitenError.self) {
      _ = try await middleware.intercept(
        HTTPRequest(method: .get, scheme: "https", authority: "test.kaiten.ru", path: "/test"),
        body: nil,
        baseURL: URL(string: "https://test.kaiten.ru")!,
        operationID: "test"
      ) { _, _, _ in
        (
          HTTPResponse(
            status: .tooManyRequests,
            headerFields: HTTPFields([
              HTTPField(name: HTTPField.Name("Retry-After")!, value: "0")
            ])), nil
        )
      }
    }
  }

  @Test("500 then 200 succeeds after retry")
  func serverErrorRetry() async throws {
    let middleware = RetryMiddleware(maxAttempts: 3, baseDelay: 0.01)
    let callCount = Mutex(0)

    let (response, _) = try await middleware.intercept(
      HTTPRequest(method: .get, scheme: "https", authority: "test.kaiten.ru", path: "/test"),
      body: nil,
      baseURL: URL(string: "https://test.kaiten.ru")!,
      operationID: "test"
    ) { _, _, _ in
      let count = callCount.withLock { val in
        val += 1
        return val
      }
      if count == 1 {
        return (HTTPResponse(status: .internalServerError), nil)
      }
      return (HTTPResponse(status: .ok), HTTPBody("{}"))
    }

    #expect(response.status == .ok)
    #expect(callCount.withLock { $0 } == 2)
  }

  @Test("5xx exhausted retries throws serverError")
  func serverErrorExhausted() async throws {
    let middleware = RetryMiddleware(maxAttempts: 3, baseDelay: 0.01)

    await #expect(throws: KaitenError.self) {
      _ = try await middleware.intercept(
        HTTPRequest(method: .get, scheme: "https", authority: "test.kaiten.ru", path: "/test"),
        body: nil,
        baseURL: URL(string: "https://test.kaiten.ru")!,
        operationID: "test"
      ) { _, _, _ in
        (HTTPResponse(status: .badGateway), nil)
      }
    }
  }

  @Test("Network error then 200 succeeds after retry")
  func networkErrorRetry() async throws {
    let middleware = RetryMiddleware(maxAttempts: 3, baseDelay: 0.01)
    let callCount = Mutex(0)

    let (response, _) = try await middleware.intercept(
      HTTPRequest(method: .get, scheme: "https", authority: "test.kaiten.ru", path: "/test"),
      body: nil,
      baseURL: URL(string: "https://test.kaiten.ru")!,
      operationID: "test"
    ) { _, _, _ in
      let count = callCount.withLock { val in
        val += 1
        return val
      }
      if count == 1 {
        throw URLError(.timedOut)
      }
      return (HTTPResponse(status: .ok), HTTPBody("{}"))
    }

    #expect(response.status == .ok)
    #expect(callCount.withLock { $0 } == 2)
  }

  @Test("Network error exhausted retries throws networkError")
  func networkErrorExhausted() async throws {
    let middleware = RetryMiddleware(maxAttempts: 3, baseDelay: 0.01)

    await #expect(throws: KaitenError.self) {
      _ = try await middleware.intercept(
        HTTPRequest(method: .get, scheme: "https", authority: "test.kaiten.ru", path: "/test"),
        body: nil,
        baseURL: URL(string: "https://test.kaiten.ru")!,
        operationID: "test"
      ) { _, _, _ in
        throw URLError(.networkConnectionLost)
      }
    }
  }

  @Test("Non-transient thrown errors are not retried")
  func nonTransientErrorNoRetry() async throws {
    let middleware = RetryMiddleware(maxAttempts: 3, baseDelay: 0.01)
    let callCount = Mutex(0)

    await #expect(throws: NonTransientError.self) {
      _ = try await middleware.intercept(
        HTTPRequest(method: .get, scheme: "https", authority: "test.kaiten.ru", path: "/test"),
        body: nil,
        baseURL: URL(string: "https://test.kaiten.ru")!,
        operationID: "test"
      ) { _, _, _ in
        callCount.withLock { $0 += 1 }
        throw NonTransientError.failed
      }
    }

    #expect(callCount.withLock { $0 } == 1)
  }

  @Test("Non-retryable status passes through immediately")
  func nonRetryableStatus() async throws {
    let middleware = RetryMiddleware(maxAttempts: 3, baseDelay: 0.01)
    let callCount = Mutex(0)

    let (response, _) = try await middleware.intercept(
      HTTPRequest(method: .get, scheme: "https", authority: "test.kaiten.ru", path: "/test"),
      body: nil,
      baseURL: URL(string: "https://test.kaiten.ru")!,
      operationID: "test"
    ) { _, _, _ in
      callCount.withLock { $0 += 1 }
      return (HTTPResponse(status: .notFound), nil)
    }

    #expect(response.status == .notFound)
    #expect(callCount.withLock { $0 } == 1)
  }

  @Test("POST requests are not retried on 5xx")
  func postNotRetriedOnServerError() async throws {
    let middleware = RetryMiddleware(maxAttempts: 3, baseDelay: 0.01)
    let callCount = Mutex(0)

    await #expect(throws: KaitenError.self) {
      _ = try await middleware.intercept(
        HTTPRequest(method: .post, scheme: "https", authority: "test.kaiten.ru", path: "/test"),
        body: HTTPBody("{}"),
        baseURL: URL(string: "https://test.kaiten.ru")!,
        operationID: "test"
      ) { _, _, _ in
        callCount.withLock { $0 += 1 }
        return (HTTPResponse(status: .internalServerError), nil)
      }
    }

    #expect(callCount.withLock { $0 } == 1)
  }
}
