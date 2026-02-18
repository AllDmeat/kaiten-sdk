import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("AddCardTag")
struct AddCardTagTests {

  @Test("200 returns Tag")
  func success() async throws {
    let json = """
      {"id": 10, "name": "urgent", "color": 2, "company_id": 1, "archived": false, "created": "2025-01-01", "updated": "2025-01-01"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let tag = try await client.addCardTag(cardId: 42, name: "urgent")
    #expect(tag.id == 10)
    #expect(tag.name == "urgent")
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.addCardTag(cardId: 999, name: "test")
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.addCardTag(cardId: 1, name: "test")
    }
  }
}
