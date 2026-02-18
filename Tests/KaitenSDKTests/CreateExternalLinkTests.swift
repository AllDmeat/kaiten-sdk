import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("CreateExternalLink")
struct CreateExternalLinkTests {

  @Test("200 returns ExternalLink")
  func success() async throws {
    let json = """
      {"id": 5, "url": "https://example.com", "description": "Example", "card_id": 42, "external_link_id": 5, "created": "2025-01-01", "updated": "2025-01-01"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let link = try await client.createExternalLink(
      cardId: 42, url: "https://example.com", description: "Example")
    #expect(link.id == 5)
    #expect(link.url == "https://example.com")
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createExternalLink(cardId: 999, url: "https://example.com")
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createExternalLink(cardId: 1, url: "https://example.com")
    }
  }
}
