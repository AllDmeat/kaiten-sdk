import Foundation
import Testing

@testable import KaitenSDK

@Suite("KaitenClient Configuration", .serialized)
struct KaitenClientConfigurationTests {

    @Test("Fails fast when KAITEN_URL is missing")
    func missingURL() {
        // Clear any env vars set by other tests
        unsetenv("KAITEN_URL")
        unsetenv("KAITEN_TOKEN")

        #expect(throws: KaitenError.self) {
            _ = try KaitenClient()
        }
    }

    @Test("Fails fast when KAITEN_TOKEN is missing")
    func missingToken() {
        setenv("KAITEN_URL", "https://test.kaiten.ru/api/latest", 1)
        unsetenv("KAITEN_TOKEN")

        defer {
            unsetenv("KAITEN_URL")
        }

        #expect(throws: KaitenError.self) {
            _ = try KaitenClient()
        }
    }
}
