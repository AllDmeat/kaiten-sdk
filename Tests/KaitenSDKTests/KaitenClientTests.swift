import Testing
@testable import KaitenSDK

@Suite("KaitenClient Configuration")
struct KaitenClientConfigurationTests {

    @Test("Fails fast when KAITEN_URL is missing")
    func missingURL() {
        #expect(throws: KaitenError.self) {
            _ = try KaitenClient()
        }
    }
}
