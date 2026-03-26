import Foundation
import HTTPTypes
import OpenAPIRuntime
import Synchronization

/// A middleware that retries requests on transient failures:
/// - HTTP 429 (Too Many Requests) respecting `Retry-After` header
/// - HTTP 5xx server errors with exponential backoff
/// - Network errors (URLError) with exponential backoff
struct RetryMiddleware: ClientMiddleware {
  private let maxAttempts: Int
  private let baseDelay: TimeInterval
  private let maxDelay: TimeInterval
  private let gate: RateLimitGate

  /// Creates a retry middleware.
  /// - Parameters:
  ///   - maxAttempts: Maximum number of attempts (default 3).
  ///   - baseDelay: Initial backoff delay in seconds (default 1.0).
  ///   - maxDelay: Maximum retry delay in seconds (default 60.0).
  ///   - gate: Shared rate-limit gate that coordinates 429 back-off across concurrent requests.
  init(
    maxAttempts: Int = 3,
    baseDelay: TimeInterval = 1.0,
    maxDelay: TimeInterval = 60.0,
    gate: RateLimitGate = RateLimitGate()
  ) {
    self.maxAttempts = maxAttempts
    self.baseDelay = baseDelay
    self.maxDelay = maxDelay
    self.gate = gate
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
    // Wait for any in-progress rate-limit window before starting.
    try await gate.waitIfNeeded()

    for attempt in 0..<maxAttempts {
      let response: HTTPResponse
      let responseBody: HTTPBody?

      do {
        (response, responseBody) = try await next(request, body, baseURL)
      } catch {
        if isTransientURLError(error) {
          // Transient network errors are only retried for idempotent methods.
          guard isRetryableMethod(request.method) else {
            throw KaitenError.networkError(underlying: error)
          }
          lastError = error
          if attempt < maxAttempts - 1 {
            try await sleep(backoffDelay(attempt: attempt))
            continue
          }
          throw KaitenError.networkError(underlying: error)
        }
        throw error
      }

      let statusCode = response.status.code

      // 429 — rate-limited. Retry ALL methods (server-side, method-agnostic).
      if statusCode == 429 {
        let retryAfter = resolveRateLimitDelay(response: response, attempt: attempt)
        lastRetryAfter = retryAfter
        let deadline = ContinuousClock.now + .seconds(retryAfter)
        await gate.markRateLimited(until: deadline)
        if attempt < maxAttempts - 1 {
          try await gate.waitIfNeeded()
          continue
        }
        throw KaitenError.rateLimited(retryAfter: lastRetryAfter)
      }

      // 5xx — only retry idempotent methods.
      if (500...599).contains(statusCode) {
        guard isRetryableMethod(request.method) else {
          throw KaitenError.serverError(statusCode: statusCode, body: nil)
        }
        if attempt < maxAttempts - 1 {
          try await sleep(backoffDelay(attempt: attempt))
          continue
        }
        let bodyString =
          if let responseBody {
            try? await String(collecting: responseBody, upTo: 8192)
          } else {
            String?.none
          }
        throw KaitenError.serverError(statusCode: statusCode, body: bodyString)
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
    return clampDelay(exponential * jitter)
  }

  private func sleep(_ duration: TimeInterval) async throws {
    try await Task.sleep(for: .seconds(duration))
  }

  /// Returns `true` for idempotent, safe HTTP methods eligible for automatic retry.
  ///
  /// Only GET and HEAD are retried. Mutating methods (POST, PUT, DELETE, PATCH)
  /// are not idempotent per RFC 9110 §9.2.2 and must not be automatically retried
  /// to avoid duplicate side effects (e.g. double-creating a resource).
  private func isRetryableMethod(_ method: HTTPRequest.Method) -> Bool {
    method == .get || method == .head
  }

  private func isTransientURLError(_ error: any Error) -> Bool {
    guard let urlError = error as? URLError else { return false }
    switch urlError.code {
    case .timedOut, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed,
      .notConnectedToInternet, .internationalRoamingOff, .callIsActive, .dataNotAllowed:
      return true
    default:
      return false
    }
  }

  private enum RateLimitHeaders {
    // swiftlint:disable force_unwrapping
    static let remaining = HTTPField.Name("X-RateLimit-Remaining")!
    static let reset = HTTPField.Name("X-RateLimit-Reset")!
    static let retryAfter = HTTPField.Name("Retry-After")!
    // swiftlint:enable force_unwrapping
  }

  private func resolveRateLimitDelay(response: HTTPResponse, attempt: Int) -> TimeInterval {
    if response.headerFields[RateLimitHeaders.remaining].flatMap(Int.init) == 0,
      let resetEpoch = response.headerFields[RateLimitHeaders.reset].flatMap(TimeInterval.init)
    {
      return clampDelay(max(0, resetEpoch - Date().timeIntervalSince1970))
    }

    if let retryAfterRaw = response.headerFields[RateLimitHeaders.retryAfter],
      let parsed = parseRetryAfter(retryAfterRaw)
    {
      return clampDelay(parsed)
    }

    return backoffDelay(attempt: attempt)
  }

  private static let httpDateFormatter = Mutex(
    {
      let f = DateFormatter()
      f.locale = Locale(identifier: "en_US_POSIX")
      f.timeZone = TimeZone(secondsFromGMT: 0)
      f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
      return f
    }())

  private func parseRetryAfter(_ value: String) -> TimeInterval? {
    if let seconds = TimeInterval(value) {
      return max(0, seconds)
    }

    if let date = Self.httpDateFormatter.withLock({ $0.date(from: value) }) {
      return max(0, date.timeIntervalSinceNow)
    }

    return nil
  }

  private func clampDelay(_ value: TimeInterval) -> TimeInterval {
    min(maxDelay, max(0, value))
  }
}
