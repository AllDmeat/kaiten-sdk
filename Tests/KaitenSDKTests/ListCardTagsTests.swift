import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("ListCardTags")
struct ListCardTagsTests {

  @Test("200 returns array of CardTag")
  func success() async throws {
    let json = """
      [{"id": 1, "name": "urgent", "color": 2, "card_id": 42, "tag_id": 10}]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let tags = try await client.listCardTags(cardId: 42)
    #expect(tags.count == 1)
    #expect(tags[0].name == "urgent")
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.listCardTags(cardId: 999)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.listCardTags(cardId: 1)
    }
  }
}
