import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("CreateCardBlocker")
struct CreateCardBlockerTests {

  @Test("200 returns created CardBlocker")
  func success() async throws {
    let json = """
      {"id": 10, "reason": "Blocked by dependency", "card_id": 42, "blocker_id": 5, "released": false}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let blocker = try await client.createCardBlocker(cardId: 42, reason: "Blocked by dependency")
    #expect(blocker.id == 10)
    #expect(blocker.reason == "Blocked by dependency")
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createCardBlocker(cardId: 999, reason: "test")
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createCardBlocker(cardId: 1, reason: "test")
    }
  }
}
