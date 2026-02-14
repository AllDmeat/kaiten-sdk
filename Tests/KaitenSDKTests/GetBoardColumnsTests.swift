import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("GetBoardColumns")
struct GetBoardColumnsTests {


    @Test("200 returns columns")
    func success() async throws {
        let json = """
            [{"id": 10, "title": "To Do", "board_id": 1}, {"id": 11, "title": "Done", "board_id": 1}]
            """
        let transport = MockClientTransport.returning(statusCode: 200, body: json)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        let columns = try await client.getBoardColumns(boardId: 1)
        #expect(columns.count == 2)
        #expect(columns[0].id == 10)
        #expect(columns[1].title == "Done")
    }

    @Test("200 empty array returns empty")
    func emptyArray() async throws {
        let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        let columns = try await client.getBoardColumns(boardId: 1)
        #expect(columns.isEmpty)
    }
}
