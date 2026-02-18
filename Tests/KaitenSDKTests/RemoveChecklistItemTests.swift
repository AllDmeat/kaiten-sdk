import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("RemoveChecklistItem")
struct RemoveChecklistItemTests {
  @Test("200 returns deleted item ID")
  func success() async throws {
    let json = """
      {"id": 42}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
    let deletedId = try await client.removeChecklistItem(
      cardId: 1, checklistId: 10, itemId: 42)
    #expect(deletedId == 42)
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
    await #expect(throws: KaitenError.self) {
      _ = try await client.removeChecklistItem(
        cardId: 999, checklistId: 10, itemId: 42)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
    await #expect(throws: KaitenError.self) {
      _ = try await client.removeChecklistItem(
        cardId: 1, checklistId: 10, itemId: 42)
    }
  }
}
