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

  @Test("Fails with non-HTTPS URL")
  func nonHTTPSURL() {
    #expect(throws: KaitenError.self) {
      _ = try KaitenClient(baseURL: "http://test.kaiten.ru/api/latest", token: "test-token")
    }
  }

  @Test("Fails with non-HTTPS URL for custom transport init")
  func nonHTTPSURLWithTransport() {
    let transport = MockClientTransport.returning(statusCode: 200, body: "{}")
    #expect(throws: KaitenError.self) {
      _ = try KaitenClient(
        baseURL: "http://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
    }
  }
}
