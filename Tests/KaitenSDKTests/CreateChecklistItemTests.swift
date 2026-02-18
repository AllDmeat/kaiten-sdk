import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("CreateChecklistItem")
struct CreateChecklistItemTests {
  @Test("200 returns created ChecklistItem")
  func success() async throws {
    let json = """
      {"id": 100, "text": "Buy milk", "sort_order": 1.5, "checked": false, "checklist_id": 10, "checker_id": null, "user_id": 1, "checked_at": null, "responsible_id": null, "deleted": false, "due_date": null, "created": "2026-01-01T00:00:00Z", "updated": "2026-01-01T00:00:00Z"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
    let item = try await client.createChecklistItem(
      cardId: 1, checklistId: 10, text: "Buy milk")
    #expect(item.id == 100)
    #expect(item.text == "Buy milk")
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
    await #expect(throws: KaitenError.self) {
      _ = try await client.createChecklistItem(
        cardId: 999, checklistId: 10, text: "Test")
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
    await #expect(throws: KaitenError.self) {
      _ = try await client.createChecklistItem(
        cardId: 1, checklistId: 10, text: "Test")
    }
  }
}
