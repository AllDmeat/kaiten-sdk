import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("GetCard")
struct GetCardTests {


    @Test("200 returns Card")
    func success() async throws {
        let json = """
            {"id": 42, "title": "Test card"}
            """
        let transport = MockClientTransport.returning(statusCode: 200, body: json)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        let card = try await client.getCard(id: 42)
        #expect(card.id == 42)
        #expect(card.title == "Test card")
    }

    @Test("404 throws notFound")
    func notFound() async throws {
        let transport = MockClientTransport.returning(statusCode: 404)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        await #expect(throws: KaitenError.self) {
            _ = try await client.getCard(id: 999)
        }
    }

    @Test("401 throws unauthorized")
    func unauthorized() async throws {
        let transport = MockClientTransport.returning(statusCode: 401)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        await #expect(throws: KaitenError.self) {
            _ = try await client.getCard(id: 1)
        }
    }
}
