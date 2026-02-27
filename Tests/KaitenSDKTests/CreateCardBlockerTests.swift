import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import KaitenSDK

@Suite("CreateCardBlocker")
struct CreateCardBlockerTests {

  private func bodyString(_ body: HTTPBody?) async throws -> String {
    guard let body else { return "" }
    var bytes = [UInt8]()
    for try await chunk in body {
      bytes.append(contentsOf: chunk)
    }
    return String(decoding: bytes, as: UTF8.self)
  }

  @Test("200 returns created CardBlocker with reason")
  func successWithReason() async throws {
    let json = """
      {
        "id": 10,
        "uid": "abc-123",
        "reason": "Blocked by dependency",
        "card_id": 42,
        "blocker_id": 5,
        "blocker_card_id": null,
        "blocker_card_title": null,
        "released": false,
        "released_by_id": null,
        "due_date": null,
        "due_date_time_present": false,
        "created": "2026-01-01T00:00:00.000Z",
        "updated": "2026-01-01T00:00:00.000Z"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let blocker = try await client.createCardBlocker(cardId: 42, reason: "Blocked by dependency")
    #expect(blocker.id == 10)
    #expect(blocker.reason == "Blocked by dependency")
    #expect(blocker.blocker_card_id == nil)
  }

  @Test("200 returns CardBlocker with blocker_card_id as integer (not string)")
  func successWithBlockerCardId() async throws {
    // NOTE: Kaiten API docs declare blocker_card_id as string, but actual API returns integer.
    // This test ensures we decode it correctly as integer.
    let json = """
      {
        "id": 11,
        "uid": "def-456",
        "reason": null,
        "card_id": 42,
        "blocker_id": 5,
        "blocker_card_id": 99,
        "blocker_card_title": null,
        "released": false,
        "released_by_id": null,
        "due_date": null,
        "due_date_time_present": false,
        "created": "2026-01-01T00:00:00.000Z",
        "updated": "2026-01-01T00:00:00.000Z"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let blocker = try await client.createCardBlocker(cardId: 42, blockerCardId: 99)
    #expect(blocker.id == 11)
    #expect(blocker.reason == nil)
    #expect(blocker.blocker_card_id == 99)

    let payload = try await bodyString(transport.recordedRequests[0].body)
    let payloadObject =
      try JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any]
    #expect(payloadObject?["blocker_card_id"] as? Int == 99)
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createCardBlocker(cardId: 999, reason: "test")
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createCardBlocker(cardId: 1, reason: "test")
    }
  }
}
