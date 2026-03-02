/// A string value that supports three distinct encoding states in a PATCH request body.
///
/// ## The problem
///
/// Swift's synthesized `Codable` uses `encodeIfPresent` for optional properties, which means
/// a `nil` value is silently **omitted** from the JSON body. This makes it impossible to
/// distinguish between two semantically different operations:
///
/// - "Don't touch this field" (field absent from JSON)
/// - "Clear this field" (field present in JSON as `null`)
///
/// Both would require passing `nil` for a `String?` parameter, but the server treats them
/// very differently.
///
/// ## The solution
///
/// `NullableString` is registered in `openapi-generator-config.yaml` via `typeOverrides.schemas`
/// to replace the generated type for the `NullableString` OpenAPI schema. Properties using
/// `$ref: '#/components/schemas/NullableString'` get generated as `NullableString?`, where:
///
/// | Swift value                      | JSON result            | Server behavior              |
/// |----------------------------------|------------------------|------------------------------|
/// | `nil` (outer optional)           | field absent           | field unchanged              |
/// | `.some(.null)`                   | `"field": null`        | field cleared                |
/// | `.some(.value("2026-03-10"))`    | `"field": "2026-03-10"`| field set to value           |
///
/// The outer `Optional` is handled by `encodeIfPresent` in the generated `Codable` synthesis —
/// `nil` means the key is omitted entirely. When present, `NullableString.encode(to:)` takes
/// over and encodes either `null` or the string value.
///
/// ## Usage in KaitenClient
///
/// Public-facing API uses `String??` for ergonomics:
///
/// ```swift
/// // Leave planned_start unchanged:
/// updateCard(id: 42)
///
/// // Clear planned_start (send null):
/// updateCard(id: 42, plannedStart: .some(nil))
///
/// // Set planned_start:
/// updateCard(id: 42, plannedStart: "2026-03-10")
/// ```
///
/// Internally, `String??` is mapped to `NullableString?`:
///
/// ```swift
/// planned_start: plannedStart.map { $0.map(NullableString.value) ?? .null }
/// ```
public enum NullableString: Codable, Hashable, Sendable {
  /// A non-null string value.
  case value(String)
  /// An explicit JSON `null` — signals the server to clear the field.
  case null

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else {
      self = .value(try container.decode(String.self))
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .value(let string):
      try container.encode(string)
    case .null:
      try container.encodeNil()
    }
  }
}

extension NullableString: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .value(value)
  }
}
