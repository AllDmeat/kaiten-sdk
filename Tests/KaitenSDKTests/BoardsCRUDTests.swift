import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Boards CRUD")
struct BoardsCRUDTests {

  // MARK: - createBoard

  @Test("createBoard 200 returns created Board")
  func createBoardSuccess() async throws {
    let json = """
      {"id": 10, "title": "Sprint Board", "space_id": 1}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    let board = try await client.createBoard(spaceId: 1, title: "Sprint Board")
    #expect(board.id == 10)
    #expect(board.title == "Sprint Board")
  }

  @Test("createBoard 401 throws unauthorized")
  func createBoardUnauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createBoard(spaceId: 1, title: "Test")
    }
  }

  @Test("createBoard 404 throws notFound (space not found)")
  func createBoardSpaceNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createBoard(spaceId: 999, title: "Test")
    }
  }

  // MARK: - updateBoard

  @Test("updateBoard 200 returns updated Board")
  func updateBoardSuccess() async throws {
    let json = """
      {"id": 10, "title": "Renamed Board", "space_id": 1}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    let board = try await client.updateBoard(spaceId: 1, id: 10, title: "Renamed Board")
    #expect(board.id == 10)
    #expect(board.title == "Renamed Board")
  }

  @Test("updateBoard 404 throws notFound")
  func updateBoardNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.updateBoard(spaceId: 1, id: 999, title: "Test")
    }
  }

}
