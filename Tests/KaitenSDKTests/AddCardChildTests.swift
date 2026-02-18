import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("AddCardChild")
struct AddCardChildTests {

  @Test("200 returns CardChild")
  func success() async throws {
    let json = """
      {"id": 5, "title": "Child card", "state": 1, "condition": 1, "board_id": 10, "column_id": 20, "lane_id": 30, "card_id": 42, "depends_on_card_id": 5}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let child = try await client.addCardChild(cardId: 42, childCardId: 5)
    #expect(child.id == 5)
    #expect(child.title == "Child card")
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.addCardChild(cardId: 999, childCardId: 5)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.addCardChild(cardId: 1, childCardId: 2)
    }
  }
}
