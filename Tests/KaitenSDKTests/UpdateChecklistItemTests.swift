import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("UpdateChecklistItem")
struct UpdateChecklistItemTests {

  @Test("200 returns updated ChecklistItem")
  func success() async throws {
    let json = """
      {"id": 100, "text": "Updated item", "sort_order": 1.5, "checked": true, "checklist_id": 10, "user_id": 1, "deleted": false}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let item = try await client.updateChecklistItem(
      cardId: 42, checklistId: 10, itemId: 100, text: "Updated item", checked: true)
    #expect(item.id == 100)
    #expect(item.text == "Updated item")
    #expect(item.checked == true)
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.updateChecklistItem(cardId: 42, checklistId: 10, itemId: 999)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.updateChecklistItem(cardId: 42, checklistId: 10, itemId: 100)
    }
  }
}
