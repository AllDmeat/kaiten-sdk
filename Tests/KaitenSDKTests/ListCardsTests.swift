import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("ListCards")
struct ListCardsTests {

  @Test("200 with array returns cards")
  func success() async throws {
    let json = """
      [{"id": 1, "title": "Card A"}, {"id": 2, "title": "Card B"}]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let page = try await client.listCards(boardId: 10)
    #expect(page.items.count == 2)
    #expect(page.items[0].id == 1)
    #expect(page.items[1].title == "Card B")
    #expect(page.offset == 0)
    #expect(page.limit == 100)
    #expect(page.hasMore == false)
  }

  @Test("200 empty array returns empty")
  func emptyArray() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let page = try await client.listCards(boardId: 10)
    #expect(page.items.isEmpty)
  }

  @Test("200 with empty body returns empty array (#84)")
  func emptyBody() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: nil)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let page = try await client.listCards(boardId: 10)
    #expect(page.items.isEmpty)
  }

  @Test("200 with empty string body returns empty array (#84)")
  func emptyStringBody() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "")
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let page = try await client.listCards(boardId: 10)
    #expect(page.items.isEmpty)
  }

  @Test("200 with invalid JSON throws decodingError (#183)")
  func invalidJsonThrowsDecodingError() async throws {
    // Simulate a schema mismatch: body is present but not a valid card array.
    let transport = MockClientTransport.returning(statusCode: 200, body: "{\"not\": \"an array\"}")
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.listCards(boardId: 10)
    }
  }

  @Test("200 with malformed JSON body throws decodingError")
  func malformedJsonThrowsDecodingError() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[")
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.listCards(boardId: 10)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.listCards(boardId: 10)
    }
  }
}
