/// A shared gate that suspends callers while a server-side 429 window is active.
///
/// Thread-safe by actor isolation. All concurrent `intercept` calls funnel through
/// `waitIfNeeded()` before touching the network — so only one sleep happens even
/// when many requests are in flight simultaneously.
actor RateLimitGate {
  private var rateLimitedUntil: ContinuousClock.Instant?

  /// Suspends the caller until any active rate-limit window has elapsed.
  func waitIfNeeded() async throws {
    guard let deadline = rateLimitedUntil else { return }
    let now = ContinuousClock.now
    if now >= deadline {
      rateLimitedUntil = nil
      return
    }
    try await Task.sleep(until: deadline, clock: .continuous)
    rateLimitedUntil = nil
  }

  /// Records a new rate-limit window. Only advances the deadline, never backward.
  func markRateLimited(until deadline: ContinuousClock.Instant) {
    if let existing = rateLimitedUntil {
      rateLimitedUntil = max(existing, deadline)
    } else {
      rateLimitedUntil = deadline
    }
  }
}
