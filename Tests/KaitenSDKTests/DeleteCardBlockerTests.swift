import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("DeleteCardBlocker")
struct DeleteCardBlockerTests {

  @Test("200 returns deleted CardBlocker")
  func success() async throws {
    let json = """
      {"id": 10, "reason": "Old blocker", "card_id": 42, "blocker_id": 5, "released": true}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let blocker = try await client.deleteCardBlocker(cardId: 42, blockerId: 10)
    #expect(blocker.id == 10)
    #expect(blocker.released == true)
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.deleteCardBlocker(cardId: 42, blockerId: 999)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.deleteCardBlocker(cardId: 1, blockerId: 1)
    }
  }
}
