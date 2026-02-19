import Foundation
import HTTPTypes
import OpenAPIRuntime

/// A middleware that retries requests on transient failures:
/// - HTTP 429 (Too Many Requests) respecting `Retry-After` header
/// - HTTP 5xx server errors with exponential backoff
/// - Network errors (URLError) with exponential backoff
struct RetryMiddleware: ClientMiddleware {
  private let maxAttempts: Int
  private let baseDelay: TimeInterval

  /// Creates a retry middleware.
  /// - Parameters:
  ///   - maxAttempts: Maximum number of attempts (default 3).
  ///   - baseDelay: Initial backoff delay in seconds (default 1.0).
  init(maxAttempts: Int = 3, baseDelay: TimeInterval = 1.0) {
    self.maxAttempts = maxAttempts
    self.baseDelay = baseDelay
  }

  // NOTE: Retrying with the same `body` reference is safe.
  // JSON request bodies use HTTPBody(data) which has .multiple iteration
  // behavior (replayable across retries). See #114 for investigation.
  func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    var lastError: (any Error)?
    var lastRetryAfter: TimeInterval?
    let attempts = isRetryableMethod(request.method) ? maxAttempts : 1

    for attempt in 0..<attempts {
      let response: HTTPResponse
      let responseBody: HTTPBody?

      do {
        (response, responseBody) = try await next(request, body, baseURL)
      } catch {
        // Network error — retry with backoff
        lastError = error
        if attempt < attempts - 1 {
          try await sleep(backoffDelay(attempt: attempt))
          continue
        }
        throw KaitenError.networkError(underlying: error)
      }

      let statusCode = response.status.code

      // Success or non-retryable status
      if statusCode == 429 {
        let retryAfter =
          response.headerFields[HTTPField.Name("Retry-After")!]
          .flatMap(TimeInterval.init)
          ?? backoffDelay(attempt: attempt)
        lastRetryAfter = retryAfter
        if attempt < attempts - 1 {
          try await sleep(retryAfter)
          continue
        }
        throw KaitenError.rateLimited(retryAfter: lastRetryAfter)
      }

      if (500...599).contains(statusCode) {
        if attempt < attempts - 1 {
          try await sleep(backoffDelay(attempt: attempt))
          continue
        }
        throw KaitenError.serverError(statusCode: statusCode, body: nil)
      }

      return (response, responseBody)
    }

    // Should not reach here, but handle gracefully
    if let lastError {
      throw KaitenError.networkError(underlying: lastError)
    }
    throw KaitenError.rateLimited(retryAfter: lastRetryAfter)
  }

  /// Calculates exponential backoff with jitter.
  private func backoffDelay(attempt: Int) -> TimeInterval {
    let exponential = baseDelay * pow(2.0, Double(attempt))
    let jitter = Double.random(in: 0.5...1.5)
    return exponential * jitter
  }

  private func sleep(_ duration: TimeInterval) async throws {
    try await Task.sleep(for: .seconds(duration))
  }

  private func isRetryableMethod(_ method: HTTPRequest.Method) -> Bool {
    method == .get || method == .head
  }
}
