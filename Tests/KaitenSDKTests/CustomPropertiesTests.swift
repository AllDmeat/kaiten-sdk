import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("CustomProperties")
struct CustomPropertiesTests {


    @Test("listCustomProperties 200 returns page")
    func listSuccess() async throws {
        let json = """
            [{"id": 1, "name": "Priority", "type": "select"}, {"id": 2, "name": "Effort", "type": "number"}]
            """
        let transport = MockClientTransport.returning(statusCode: 200, body: json)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        let page = try await client.listCustomProperties()
        #expect(page.items.count == 2)
        #expect(page.items[0].name == "Priority")
        #expect(page.offset == 0)
        #expect(page.limit == 100)
    }

    @Test("getCustomProperty 200 returns single")
    func getSuccess() async throws {
        let json = """
            {"id": 1, "name": "Priority", "type": "select"}
            """
        let transport = MockClientTransport.returning(statusCode: 200, body: json)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        let prop = try await client.getCustomProperty(id: 1)
        #expect(prop.name == "Priority")
    }

    @Test("getCustomProperty 404 throws notFound")
    func notFound() async throws {
        let transport = MockClientTransport.returning(statusCode: 404)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        await #expect(throws: KaitenError.self) {
            _ = try await client.getCustomProperty(id: 999)
        }
    }
}
