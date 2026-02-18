import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("UpdateCardMemberRole")
struct UpdateCardMemberRoleTests {

  @Test("200 returns updated role")
  func success() async throws {
    let json = """
      {"card_id": 42, "user_id": 10, "type": 2, "updated": "2025-01-01", "created": "2025-01-01"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let role = try await client.updateCardMemberRole(cardId: 42, userId: 10, type: .responsible)
    #expect(role.card_id == 42)
    #expect(role.user_id == 10)
    #expect(role._type == 2)
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.updateCardMemberRole(cardId: 999, userId: 10, type: .responsible)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.updateCardMemberRole(cardId: 42, userId: 10, type: .responsible)
    }
  }
}
