import Foundation
import Testing

@testable import KaitenSDK

@Suite("KaitenClient Configuration")
struct KaitenClientConfigurationTests {

    @Test("Fails with invalid URL")
    func invalidURL() {
        #expect(throws: KaitenError.self) {
            _ = try KaitenClient(baseURL: "", token: "test-token")
        }
    }
}
