import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("RemoveCardMember")
struct RemoveCardMemberTests {

  @Test("200 returns deleted id")
  func success() async throws {
    let json = """
      {"id": 10}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let deletedId = try await client.removeCardMember(cardId: 42, userId: 10)
    #expect(deletedId == 10)
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.removeCardMember(cardId: 999, userId: 10)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.removeCardMember(cardId: 42, userId: 10)
    }
  }
}
