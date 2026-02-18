import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("ListCardChildren")
struct ListCardChildrenTests {

  @Test("200 returns array of CardChild")
  func success() async throws {
    let json = """
      [{"id": 1, "title": "Child card", "state": 1, "condition": 1, "board_id": 10, "column_id": 20, "lane_id": 30, "card_id": 42, "depends_on_card_id": 1}]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let children = try await client.listCardChildren(cardId: 42)
    #expect(children.count == 1)
    #expect(children[0].title == "Child card")
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.listCardChildren(cardId: 999)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.listCardChildren(cardId: 1)
    }
  }
}
