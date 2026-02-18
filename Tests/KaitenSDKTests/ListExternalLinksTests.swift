import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("ListExternalLinks")
struct ListExternalLinksTests {

  @Test("200 returns array of ExternalLink")
  func success() async throws {
    let json = """
      [{"id": 1, "url": "https://example.com", "description": "Example", "card_id": 42, "external_link_id": 1, "created": "2025-01-01", "updated": "2025-01-01"}]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let links = try await client.listExternalLinks(cardId: 42)
    #expect(links.count == 1)
    #expect(links[0].id == 1)
    #expect(links[0].url == "https://example.com")
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.listExternalLinks(cardId: 999)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.listExternalLinks(cardId: 1)
    }
  }
}
