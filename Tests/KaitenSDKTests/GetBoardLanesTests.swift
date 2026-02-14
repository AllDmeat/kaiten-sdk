import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("GetBoardLanes")
struct GetBoardLanesTests {


    @Test("200 returns lanes")
    func success() async throws {
        let json = """
            [{"id": "20", "title": "Default Lane", "board_id": 1}, {"id": "21", "title": "Urgent", "board_id": 1}]
            """
        let transport = MockClientTransport.returning(statusCode: 200, body: json)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        let lanes = try await client.getBoardLanes(boardId: 1)
        #expect(lanes.count == 2)
        #expect(lanes[0].id == "20")
        #expect(lanes[1].title == "Urgent")
    }

    @Test("200 empty array returns empty")
    func emptyArray() async throws {
        let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        let lanes = try await client.getBoardLanes(boardId: 1)
        #expect(lanes.isEmpty)
    }
}
