import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("GetCurrentUser")
struct GetCurrentUserTests {

  @Test("200 returns current user")
  func success() async throws {
    let json = """
      {"id": 42, "uid": "def-456", "full_name": "Current User", "email": "me@example.com", "username": "me", "activated": true, "role": 1, "company_id": 1, "user_id": 42, "external": false, "virtual": false}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let user = try await client.getCurrentUser()
    #expect(user.id == 42)
    #expect(user.full_name == "Current User")
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.getCurrentUser()
    }
  }
}
