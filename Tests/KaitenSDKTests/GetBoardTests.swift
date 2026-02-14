import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("GetBoard")
struct GetBoardTests {


    @Test("200 returns Board")
    func success() async throws {
        let json = """
            {"id": 1, "title": "My Board"}
            """
        let transport = MockClientTransport.returning(statusCode: 200, body: json)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        let board = try await client.getBoard(id: 1)
        #expect(board.id == 1)
        #expect(board.title == "My Board")
    }

    @Test("404 throws notFound")
    func notFound() async throws {
        let transport = MockClientTransport.returning(statusCode: 404)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        await #expect(throws: KaitenError.self) {
            _ = try await client.getBoard(id: 999)
        }
    }

    @Test("401 throws unauthorized")
    func unauthorized() async throws {
        let transport = MockClientTransport.returning(statusCode: 401)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        await #expect(throws: KaitenError.self) {
            _ = try await client.getBoard(id: 1)
        }
    }
}
