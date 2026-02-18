import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("GetChecklist")
struct GetChecklistTests {

  @Test("200 returns Checklist")
  func success() async throws {
    let json = """
      {"id": 100, "name": "My checklist"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let checklist = try await client.getChecklist(cardId: 1, checklistId: 100)
    #expect(checklist.id == 100)
    #expect(checklist.name == "My checklist")
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.getChecklist(cardId: 1, checklistId: 999)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.getChecklist(cardId: 1, checklistId: 1)
    }
  }
}
