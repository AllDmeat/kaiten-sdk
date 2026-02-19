import Foundation
import Testing

@testable import KaitenSDK

@Suite("Enums")
struct EnumsTests {
  private func assertRoundTrip<T: CaseIterable & RawRepresentable & Equatable>(
    _ type: T.Type
  ) where T.RawValue == Int {
    for value in T.allCases {
      #expect(T(rawValue: value.rawValue) == value)
    }
  }

  @Test("all public enums support raw value round-trip")
  func roundTrip() {
    assertRoundTrip(CardCondition.self)
    assertRoundTrip(LaneCondition.self)
    assertRoundTrip(CardState.self)
    assertRoundTrip(CardMemberRoleType.self)
    assertRoundTrip(TextFormatType.self)
    assertRoundTrip(CardPosition.self)
    assertRoundTrip(ColumnType.self)
    assertRoundTrip(WipLimitType.self)
  }

  @Test("invalid raw values return nil for all public enums")
  func invalidRawValue() {
    #expect(CardCondition(rawValue: 999) == nil)
    #expect(LaneCondition(rawValue: 999) == nil)
    #expect(CardState(rawValue: 999) == nil)
    #expect(CardMemberRoleType(rawValue: 999) == nil)
    #expect(TextFormatType(rawValue: 999) == nil)
    #expect(CardPosition(rawValue: 999) == nil)
    #expect(ColumnType(rawValue: 999) == nil)
    #expect(WipLimitType(rawValue: 999) == nil)
  }

  @Test("case counts are stable for public enums")
  func caseCounts() {
    #expect(CardCondition.allCases.count == 2)
    #expect(LaneCondition.allCases.count == 3)
    #expect(CardState.allCases.count == 3)
    #expect(CardMemberRoleType.allCases.count == 2)
    #expect(TextFormatType.allCases.count == 3)
    #expect(CardPosition.allCases.count == 2)
    #expect(ColumnType.allCases.count == 3)
    #expect(WipLimitType.allCases.count == 2)
  }

  @Test("listCards query uses expected enum raw values")
  func queryEncodingUsesRawValues() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest",
      token: "test-token",
      transport: transport
    )
    let filter = KaitenClient.CardFilter(
      condition: .archived,
      states: [.queued, .done]
    )

    _ = try await client.listCards(boardId: 10, filter: filter)

    #expect(transport.recordedRequests.count == 1)
    let requestPath = String(describing: transport.recordedRequests[0].request.path)
    #expect(requestPath.contains("condition=2"))
    #expect(requestPath.contains("states=1,3") || requestPath.contains("states=1%2C3"))
  }
}
