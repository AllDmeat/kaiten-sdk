import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("CustomProperties")
struct CustomPropertiesTests {


    @Test("listCustomProperties 200 returns array")
    func listSuccess() async throws {
        let json = """
            [{"id": 1, "name": "Priority", "type": "select"}, {"id": 2, "name": "Effort", "type": "number"}]
            """
        let transport = MockClientTransport.returning(statusCode: 200, body: json)
        let client = try KaitenClient(baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

        let props = try await client.listCustomProperties()
        #expect(props.count == 2)
        #expect(props[0].name == "Priority")
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
