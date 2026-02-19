import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Spaces CRUD")
struct SpacesCRUDTests {

  // MARK: - getSpace

  @Test("getSpace 200 returns Space")
  func getSpaceSuccess() async throws {
    let json = """
      {"id": 1, "title": "My Space"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    let space = try await client.getSpace(id: 1)
    #expect(space.id == 1)
    #expect(space.title == "My Space")
  }

  @Test("getSpace 404 throws notFound")
  func getSpaceNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.getSpace(id: 999)
    }
  }

  @Test("getSpace 401 throws unauthorized")
  func getSpaceUnauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.getSpace(id: 1)
    }
  }

  // MARK: - createSpace

  @Test("createSpace 200 returns created Space")
  func createSpaceSuccess() async throws {
    let json = """
      {"id": 2, "title": "New Space"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    let space = try await client.createSpace(title: "New Space")
    #expect(space.id == 2)
    #expect(space.title == "New Space")
  }

  @Test("createSpace 401 throws unauthorized")
  func createSpaceUnauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createSpace(title: "Test")
    }
  }

  @Test("createSpace 403 throws error")
  func createSpaceForbidden() async throws {
    let transport = MockClientTransport.returning(statusCode: 403)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createSpace(title: "Test")
    }
  }

  // MARK: - updateSpace

  @Test("updateSpace 200 returns updated Space")
  func updateSpaceSuccess() async throws {
    let json = """
      {"id": 1, "title": "Updated Space"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    let space = try await client.updateSpace(id: 1, title: "Updated Space")
    #expect(space.id == 1)
    #expect(space.title == "Updated Space")
  }

  @Test("updateSpace 404 throws notFound")
  func updateSpaceNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.updateSpace(id: 999, title: "Test")
    }
  }

}
