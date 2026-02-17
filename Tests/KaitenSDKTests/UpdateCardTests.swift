import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("UpdateCard")
struct UpdateCardTests {

    @Test("200 returns updated Card")
    func success() async throws {
        let json = """
            {"id": 42, "title": "Updated title", "description": "New desc"}
            """
        let transport = MockClientTransport.returning(statusCode: 200, body: json)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        let card = try await client.updateCard(id: 42, title: "Updated title", description: "New desc")
        #expect(card.id == 42)
        #expect(card.title == "Updated title")
        #expect(card.description == "New desc")
    }

    @Test("404 throws notFound")
    func notFound() async throws {
        let transport = MockClientTransport.returning(statusCode: 404)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        await #expect(throws: KaitenError.self) {
            _ = try await client.updateCard(id: 999, title: "x")
        }
    }

    @Test("401 throws unauthorized")
    func unauthorized() async throws {
        let transport = MockClientTransport.returning(statusCode: 401)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        await #expect(throws: KaitenError.self) {
            _ = try await client.updateCard(id: 1, title: "x")
        }
    }
}
