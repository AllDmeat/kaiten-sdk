import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("ListCards")
struct ListCardsTests {

    init() {
        setenv("KAITEN_URL", "https://test.kaiten.ru/api/latest", 1)
        setenv("KAITEN_TOKEN", "test-token", 1)
    }

    @Test("200 with array returns cards")
    func success() async throws {
        let json = """
            [{"id": 1, "title": "Card A"}, {"id": 2, "title": "Card B"}]
            """
        let transport = MockClientTransport.returning(statusCode: 200, body: json)
        let client = try KaitenClient(transport: transport)

        let cards = try await client.listCards(boardId: 10)
        #expect(cards.count == 2)
        #expect(cards[0].id == 1)
        #expect(cards[1].title == "Card B")
    }

    @Test("200 empty array returns empty")
    func emptyArray() async throws {
        let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
        let client = try KaitenClient(transport: transport)

        let cards = try await client.listCards(boardId: 10)
        #expect(cards.isEmpty)
    }

    @Test("401 throws unauthorized")
    func unauthorized() async throws {
        let transport = MockClientTransport.returning(statusCode: 401)
        let client = try KaitenClient(transport: transport)

        await #expect(throws: KaitenError.self) {
            _ = try await client.listCards(boardId: 10)
        }
    }
}
