import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("ListSpaces")
struct ListSpacesTests {


    @Test("200 returns spaces")
    func success() async throws {
        let json = """
            [{"id": 1, "title": "Engineering"}, {"id": 2, "title": "Design"}]
            """
        let transport = MockClientTransport.returning(statusCode: 200, body: json)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        let spaces = try await client.listSpaces()
        #expect(spaces.count == 2)
        #expect(spaces[0].id == 1)
        #expect(spaces[1].title == "Design")
    }

    @Test("200 empty array returns empty")
    func emptyArray() async throws {
        let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        let spaces = try await client.listSpaces()
        #expect(spaces.isEmpty)
    }

    @Test("401 throws unauthorized")
    func unauthorized() async throws {
        let transport = MockClientTransport.returning(statusCode: 401)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        await #expect(throws: KaitenError.self) {
            _ = try await client.listSpaces()
        }
    }
}
