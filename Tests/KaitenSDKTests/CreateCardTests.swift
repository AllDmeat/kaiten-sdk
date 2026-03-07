import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("CreateCard")
struct CreateCardTests {

  @Test("200 returns created Card")
  func success() async throws {
    let json = """
      {"id": 123, "title": "New card", "board_id": 1}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let card = try await client.createCard(CardCreateOptions(title: "New card", boardId: 1))
    #expect(card.id == 123)
    #expect(card.title == "New card")
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createCard(CardCreateOptions(title: "Test", boardId: 1))
    }
  }

  @Test("400 throws unexpectedResponse")
  func badRequest() async throws {
    let transport = MockClientTransport.returning(statusCode: 400)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createCard(CardCreateOptions(title: "Test", boardId: 1))
    }
  }

  @Test("403 throws unexpectedResponse")
  func forbidden() async throws {
    let transport = MockClientTransport.returning(statusCode: 403)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createCard(CardCreateOptions(title: "Test", boardId: 1))
    }
  }
}
