import Foundation
import Testing

@testable import KaitenSDK

@Suite("NullableString")
struct NullableStringTests {

  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  // MARK: - Encoding

  @Test("encodes .value as JSON string")
  func encodeValue() throws {
    let data = try encoder.encode(NullableString.value("2026-03-10"))
    let json = String(data: data, encoding: .utf8)
    #expect(json == "\"2026-03-10\"")
  }

  @Test("encodes .null as JSON null")
  func encodeNull() throws {
    let data = try encoder.encode(NullableString.null)
    let json = String(data: data, encoding: .utf8)
    #expect(json == "null")
  }

  @Test("optional .some(.value) encodes as string when wrapped in container")
  func encodeOptionalValue() throws {
    struct Wrapper: Encodable {
      let field: NullableString?
    }
    let data = try encoder.encode(Wrapper(field: .value("hello")))
    let json = String(data: data, encoding: .utf8)!
    #expect(json.contains("\"hello\""))
    #expect(json.contains("\"field\""))
  }

  @Test("optional .some(.null) encodes as explicit null in container")
  func encodeOptionalNull() throws {
    struct Wrapper: Encodable {
      let field: NullableString?
    }
    let data = try encoder.encode(Wrapper(field: .null))
    let json = String(data: data, encoding: .utf8)!
    // key present with null value
    #expect(json.contains("\"field\""))
    #expect(json.contains("null"))
  }

  @Test("optional nil omits key from container")
  func encodeOptionalNilOmitsKey() throws {
    struct Wrapper: Encodable {
      let field: NullableString?
    }
    let data = try encoder.encode(Wrapper(field: nil))
    let json = String(data: data, encoding: .utf8)!
    // key must be absent entirely
    #expect(!json.contains("field"))
  }

  // MARK: - Decoding

  @Test("decodes JSON string as .value")
  func decodeValue() throws {
    let data = Data("\"2026-03-10\"".utf8)
    let result = try decoder.decode(NullableString.self, from: data)
    #expect(result == .value("2026-03-10"))
  }

  @Test("decodes JSON null as .null")
  func decodeNull() throws {
    let data = Data("null".utf8)
    let result = try decoder.decode(NullableString.self, from: data)
    #expect(result == .null)
  }

  // MARK: - Round-trip

  @Test("round-trip .value")
  func roundTripValue() throws {
    let original = NullableString.value("2026-12-31")
    let data = try encoder.encode(original)
    let decoded = try decoder.decode(NullableString.self, from: data)
    #expect(decoded == original)
  }

  @Test("round-trip .null")
  func roundTripNull() throws {
    let original = NullableString.null
    let data = try encoder.encode(original)
    let decoded = try decoder.decode(NullableString.self, from: data)
    #expect(decoded == original)
  }

  // MARK: - ExpressibleByStringLiteral

  @Test("string literal creates .value")
  func stringLiteral() {
    let ns: NullableString = "hello"
    #expect(ns == .value("hello"))
  }
}
