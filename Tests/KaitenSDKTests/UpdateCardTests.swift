import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("UpdateCard")
struct UpdateCardTests {

  private let cardJSON = """
    {"id": 42, "title": "Updated title", "description": "New desc"}
    """

  @Test("200 returns updated Card")
  func success() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: cardJSON)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let card = try await client.updateCard(id: 42, title: "Updated title", description: "New desc")
    #expect(card.id == 42)
    #expect(card.title == "Updated title")
    #expect(card.description == "New desc")
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.updateCard(id: 999, title: "x")
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.updateCard(id: 1, title: "x")
    }
  }

  // MARK: - planned_start / planned_end three-state encoding

  /// Reads the recorded request body as a JSON dictionary.
  private func requestBodyJSON(from transport: MockClientTransport) async throws -> [String: Any] {
    let req = try #require(transport.recordedRequests.first)
    let bodyData = try await Data(collecting: #require(req.body), upTo: 1024 * 1024)
    return try #require(
      try JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
    )
  }

  @Test("plannedStart nil omits planned_start from request body")
  func plannedStartNilOmitsKey() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: cardJSON)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    _ = try await client.updateCard(id: 42, plannedStart: nil)

    let body = try await requestBodyJSON(from: transport)
    #expect(body["planned_start"] == nil, "planned_start should be absent when nil")
  }

  @Test("plannedStart .some(nil) sends planned_start as JSON null")
  func plannedStartSomeNilSendsNull() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: cardJSON)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    _ = try await client.updateCard(id: 42, plannedStart: .some(nil))

    let body = try await requestBodyJSON(from: transport)
    #expect(body["planned_start"] is NSNull, "planned_start should be JSON null when .some(nil)")
  }

  @Test("plannedStart .some(date) sends planned_start as string")
  func plannedStartSomeDateSendsString() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: cardJSON)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    _ = try await client.updateCard(id: 42, plannedStart: "2026-03-10")

    let body = try await requestBodyJSON(from: transport)
    #expect(body["planned_start"] as? String == "2026-03-10")
  }

  @Test("plannedEnd nil omits planned_end from request body")
  func plannedEndNilOmitsKey() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: cardJSON)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    _ = try await client.updateCard(id: 42, plannedEnd: nil)

    let body = try await requestBodyJSON(from: transport)
    #expect(body["planned_end"] == nil, "planned_end should be absent when nil")
  }

  @Test("plannedEnd .some(nil) sends planned_end as JSON null")
  func plannedEndSomeNilSendsNull() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: cardJSON)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    _ = try await client.updateCard(id: 42, plannedEnd: .some(nil))

    let body = try await requestBodyJSON(from: transport)
    #expect(body["planned_end"] is NSNull, "planned_end should be JSON null when .some(nil)")
  }

  @Test("plannedEnd .some(date) sends planned_end as string")
  func plannedEndSomeDateSendsString() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: cardJSON)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    _ = try await client.updateCard(id: 42, plannedEnd: "2026-12-31")

    let body = try await requestBodyJSON(from: transport)
    #expect(body["planned_end"] as? String == "2026-12-31")
  }
}
