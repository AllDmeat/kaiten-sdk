import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import KaitenSDK

@Suite("CreateComment")
struct CreateCommentTests {
  private func bodyString(_ body: HTTPBody?) async throws -> String {
    guard let body else { return "" }
    var bytes = [UInt8]()
    for try await chunk in body {
      bytes.append(contentsOf: chunk)
    }
    return String(decoding: bytes, as: UTF8.self)
  }

  @Test("200 returns created Comment and sends expected payload")
  func success() async throws {
    let json = """
      {"id": 100, "uid": "abc-123", "text": "Hello", "type": 1, "edited": false, "card_id": 42, "author_id": 5, "internal": false, "deleted": false, "sd_description": false, "updated": "2026-02-18T03:13:29Z", "created": "2026-02-17T13:05:28Z"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest",
      token: "test-token",
      transport: transport
    )

    let comment = try await client.createComment(cardId: 42, text: "Hello")
    #expect(comment.id == 100)
    #expect(comment.text == "Hello")

    #expect(transport.recordedRequests.count == 1)
    let request = transport.recordedRequests[0]
    #expect(request.request.method == .post)
    #expect(String(describing: request.request.path).contains("/cards/42/comments"))

    let payload = try await bodyString(request.body)
    let payloadObject =
      try JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: String]
    #expect(payloadObject?["text"] == "Hello")
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest",
      token: "test-token",
      transport: transport
    )

    await #expect(throws: KaitenError.self) {
      _ = try await client.createComment(cardId: 42, text: "Hello")
    }
  }
}
