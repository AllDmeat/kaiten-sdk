import Foundation
import Testing

@testable import KaitenSDK

@Suite("KaitenError")
struct KaitenErrorTests {
  private struct UnderlyingError: Error, LocalizedError {
    var errorDescription: String? { "underlying error" }
  }

  @Test("all relevant error descriptions are non-empty and stable")
  func errorDescriptions() {
    let cases: [(KaitenError, String)] = [
      (.missingConfiguration("TOKEN"), "Missing required configuration: TOKEN"),
      (.invalidURL("not a url"), "Invalid URL: not a url"),
      (.unauthorized, "Unauthorized – check your API token"),
      (.notFound(resource: "card", id: 42), "card with id 42 not found"),
      (.rateLimited(retryAfter: nil), "Rate limited – retry later"),
      (.rateLimited(retryAfter: 5), "Rate limited – retry after 5s"),
      (.serverError(statusCode: 500, body: "oops"), "Server error 500: oops"),
      (.networkError(underlying: UnderlyingError()), "Network error: underlying error"),
      (.decodingError(underlying: UnderlyingError()), "Decoding error: underlying error"),
      (
        .unexpectedResponse(statusCode: 418, body: "teapot"),
        "Unexpected HTTP response: 418: teapot"
      ),
    ]

    for (error, expected) in cases {
      let description = error.errorDescription
      #expect(description == expected)
      #expect(description?.isEmpty == false)
    }
  }
}
