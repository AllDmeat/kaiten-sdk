import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("GetCardMembers")
struct GetCardMembersTests {

    init() {
        setenv("KAITEN_URL", "https://test.kaiten.ru/api/latest", 1)
        setenv("KAITEN_TOKEN", "test-token", 1)
    }

    @Test("200 returns members")
    func success() async throws {
        let json = """
            [{"id": 1, "full_name": "Alice"}, {"id": 2, "full_name": "Bob"}]
            """
        let transport = MockClientTransport.returning(statusCode: 200, body: json)
        let client = try KaitenClient(transport: transport)

        let members = try await client.getCardMembers(cardId: 42)
        #expect(members.count == 2)
        #expect(members[0].full_name == "Alice")
    }

    @Test("200 empty returns empty")
    func emptyArray() async throws {
        let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
        let client = try KaitenClient(transport: transport)

        let members = try await client.getCardMembers(cardId: 42)
        #expect(members.isEmpty)
    }
}
