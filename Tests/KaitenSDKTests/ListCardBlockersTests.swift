import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("ListCardBlockers")
struct ListCardBlockersTests {

  @Test("200 returns array of CardBlocker")
  func success() async throws {
    let json = """
      [{"id": 1, "reason": "Waiting for design", "card_id": 42, "blocker_id": 5, "released": false}]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let blockers = try await client.listCardBlockers(cardId: 42)
    #expect(blockers.count == 1)
    #expect(blockers[0].reason == "Waiting for design")
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.listCardBlockers(cardId: 999)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.listCardBlockers(cardId: 1)
    }
  }
}
