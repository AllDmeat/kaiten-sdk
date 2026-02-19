import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Lanes CRUD")
struct LanesCRUDTests {

  // MARK: - createLane

  @Test("createLane 200 returns created Lane")
  func createLaneSuccess() async throws {
    let json = """
      {"id": 200, "title": "Default Lane", "board_id": 10}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    let lane = try await client.createLane(boardId: 10, title: "Default Lane")
    #expect(lane.id == 200)
    #expect(lane.title == "Default Lane")
  }

  @Test("createLane 401 throws unauthorized")
  func createLaneUnauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createLane(boardId: 10, title: "Test")
    }
  }

  @Test("createLane 404 throws notFound (board not found)")
  func createLaneBoardNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createLane(boardId: 999, title: "Test")
    }
  }

  // MARK: - updateLane

  @Test("updateLane 200 returns updated Lane")
  func updateLaneSuccess() async throws {
    let json = """
      {"id": 200, "title": "Urgent Lane", "board_id": 10}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    let lane = try await client.updateLane(boardId: 10, id: 200, title: "Urgent Lane")
    #expect(lane.id == 200)
    #expect(lane.title == "Urgent Lane")
  }

  @Test("updateLane 404 throws notFound")
  func updateLaneNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.updateLane(boardId: 10, id: 999, title: "Test")
    }
  }

}
