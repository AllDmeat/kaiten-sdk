import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("ListUsers")
struct ListUsersTests {

  @Test("200 returns array of users")
  func success() async throws {
    let json = """
      [{"id": 1, "uid": "abc-123", "full_name": "Test User", "email": "test@example.com", "username": "testuser", "activated": true, "role": 2, "company_id": 1, "user_id": 1, "external": false, "virtual": false}]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let users = try await client.listUsers()
    #expect(users.count == 1)
    #expect(users[0].full_name == "Test User")
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.listUsers()
    }
  }
}
