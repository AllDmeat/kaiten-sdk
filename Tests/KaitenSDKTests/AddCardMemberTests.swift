import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("AddCardMember")
struct AddCardMemberTests {

  @Test("200 returns member")
  func success() async throws {
    let json = """
      {"id": 10, "full_name": "Alice", "type": 1}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let member = try await client.addCardMember(cardId: 42, userId: 10)
    #expect(member.id == 10)
    #expect(member.full_name == "Alice")
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.addCardMember(cardId: 999, userId: 10)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.addCardMember(cardId: 42, userId: 10)
    }
  }
}
