import Testing

@testable import KaitenSDK

@Suite("RateLimitGate")
struct RateLimitGateTests {

  @Test("waitIfNeeded returns immediately when no deadline is set")
  func noDeadline() async throws {
    let gate = RateLimitGate()
    try await gate.waitIfNeeded()
  }

  @Test("waitIfNeeded suspends until deadline elapses")
  func suspendsUntilDeadline() async throws {
    let gate = RateLimitGate()
    let delay: ContinuousClock.Duration = .milliseconds(50)
    let deadline = ContinuousClock.now + delay

    await gate.markRateLimited(until: deadline)

    let start = ContinuousClock.now
    try await gate.waitIfNeeded()
    let elapsed = ContinuousClock.now - start

    #expect(elapsed >= delay)
  }

  @Test("markRateLimited only advances the deadline forward")
  func deadlineOnlyAdvances() async throws {
    let gate = RateLimitGate()
    let later = ContinuousClock.now + .milliseconds(200)
    let earlier = ContinuousClock.now + .milliseconds(50)

    await gate.markRateLimited(until: later)
    // This earlier deadline should be ignored.
    await gate.markRateLimited(until: earlier)

    let start = ContinuousClock.now
    try await gate.waitIfNeeded()
    let elapsed = ContinuousClock.now - start

    // Should have waited for the later deadline (~200ms), not the earlier one (~50ms).
    #expect(elapsed >= .milliseconds(150))
  }

  @Test("waitIfNeeded clears expired deadline without sleeping")
  func expiredDeadline() async throws {
    let gate = RateLimitGate()
    // Set a deadline that is already in the past.
    await gate.markRateLimited(until: ContinuousClock.now - .milliseconds(10))

    let start = ContinuousClock.now
    try await gate.waitIfNeeded()
    let elapsed = ContinuousClock.now - start

    // Should return almost immediately.
    #expect(elapsed < .milliseconds(50))
  }
}
