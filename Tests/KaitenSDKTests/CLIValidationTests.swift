import ArgumentParser
import Testing

@testable import kaiten

@Suite("CLI validation")
struct CLIValidationTests {
  @Test("Card member role parser rejects unknown value")
  func cardMemberRoleRejectsUnknown() {
    #expect(throws: ValidationError.self) {
      _ = try parseCardMemberRoleType(999)
    }
  }

  @Test("Card states parser trims whitespace")
  func cardStatesTrimsWhitespace() throws {
    let parsed = try parseCardStates("1, 2")
    #expect(parsed?.count == 2)
  }

  @Test("Card states parser rejects invalid token")
  func cardStatesRejectsInvalidToken() {
    #expect(throws: ValidationError.self) {
      _ = try parseCardStates("1,abc")
    }
  }

  @Test("Lane condition parser rejects unknown value")
  func laneConditionRejectsUnknown() {
    #expect(throws: ValidationError.self) {
      _ = try parseLaneCondition(999)
    }
  }
}
