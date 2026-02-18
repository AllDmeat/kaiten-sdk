import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("RemoveExternalLink")
struct RemoveExternalLinkTests {

  @Test("200 returns deleted ID")
  func success() async throws {
    let json = """
      {"id": 5}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let deletedId = try await client.removeExternalLink(cardId: 42, linkId: 5)
    #expect(deletedId == 5)
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.removeExternalLink(cardId: 42, linkId: 999)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.removeExternalLink(cardId: 1, linkId: 1)
    }
  }
}
