import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("CardComments")
struct CardCommentsTests {

    @Test("getCardComments 200 returns array")
    func listSuccess() async throws {
        let json = """
            [{"id": 1, "uid": "abc-123", "text": "Hello", "type": 1, "edited": false, "card_id": 100, "author_id": 5, "internal": false, "deleted": false, "sd_description": false, "updated": "2025-01-01T00:00:00Z", "created": "2025-01-01T00:00:00Z"}]
            """
        let transport = MockClientTransport.returning(statusCode: 200, body: json)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        let comments = try await client.getCardComments(cardId: 100)
        #expect(comments.count == 1)
        #expect(comments[0].text == "Hello")
    }

    @Test("getCardComments 404 throws notFound")
    func notFound() async throws {
        let transport = MockClientTransport.returning(statusCode: 404)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        await #expect(throws: KaitenError.self) {
            _ = try await client.getCardComments(cardId: 999)
        }
    }
}
