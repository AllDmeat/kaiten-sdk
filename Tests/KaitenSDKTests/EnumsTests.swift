import Foundation
import Testing

@testable import KaitenSDK

@Suite("Enums")
struct EnumsTests {
  @Test("all public enums support raw value round-trip for known cases")
  func roundTrip() {
    for c in CardCondition.allCases {
      #expect(CardCondition(rawValue: c.rawValue) == c)
    }
    for c in LaneCondition.allCases {
      #expect(LaneCondition(rawValue: c.rawValue) == c)
    }
    for c in CardState.allCases {
      #expect(CardState(rawValue: c.rawValue) == c)
    }
    for c in CardMemberRoleType.allCases {
      #expect(CardMemberRoleType(rawValue: c.rawValue) == c)
    }
    for c in TextFormatType.allCases {
      #expect(TextFormatType(rawValue: c.rawValue) == c)
    }
    for c in CardPosition.allCases {
      #expect(CardPosition(rawValue: c.rawValue) == c)
    }
    for c in ColumnType.allCases {
      #expect(ColumnType(rawValue: c.rawValue) == c)
    }
    for c in WipLimitType.allCases {
      #expect(WipLimitType(rawValue: c.rawValue) == c)
    }
    for c in CardHistoryCondition.allCases {
      #expect(CardHistoryCondition(rawValue: c.rawValue) == c)
    }
  }

  @Test("unknown raw values produce .unknown case for all public enums")
  func unknownRawValue() {
    #expect(CardCondition(rawValue: 999) == .unknown(999))
    #expect(LaneCondition(rawValue: 999) == .unknown(999))
    #expect(CardState(rawValue: 999) == .unknown(999))
    #expect(CardMemberRoleType(rawValue: 999) == .unknown(999))
    #expect(TextFormatType(rawValue: 999) == .unknown(999))
    #expect(CardPosition(rawValue: 999) == .unknown(999))
    #expect(ColumnType(rawValue: 999) == .unknown(999))
    #expect(WipLimitType(rawValue: 999) == .unknown(999))
    #expect(CardHistoryCondition(rawValue: 999) == .unknown(999))
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
    #expect(CardHistoryCondition.allCases.count == 3)
  }

  @Test("CardHistoryCondition raw values match Kaiten API")
  func cardHistoryConditionValues() {
    #expect(CardHistoryCondition.active.rawValue == 1)
    #expect(CardHistoryCondition.archived.rawValue == 2)
    #expect(CardHistoryCondition.deleted.rawValue == 3)
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

  @Test("unknown raw values round-trip through Codable")
  func unknownCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    let original = CardCondition.unknown(42)
    let data = try encoder.encode(original)
    let decoded = try decoder.decode(CardCondition.self, from: data)
    #expect(decoded == original)
    #expect(decoded.rawValue == 42)
  }
}
