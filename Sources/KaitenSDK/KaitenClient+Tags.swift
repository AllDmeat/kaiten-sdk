import Foundation
import OpenAPIRuntime

// MARK: - Card Tags

extension KaitenClient {
  /// Lists all tags on a card.
  ///
  /// - Parameter cardId: The card identifier.
  /// - Returns: An array of card tags.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listCardTags(cardId: Int) async throws(KaitenError) -> [Components.Schemas.CardTag] {
    guard
      let response = try await callList({
        try await client.list_card_tags(path: .init(card_id: cardId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }

  /// Adds a tag to a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - name: The tag name.
  /// - Returns: The created tag.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func addCardTag(cardId: Int, name: String) async throws(KaitenError)
    -> Components
    .Schemas.Tag
  {
    let response = try await call {
      try await client.add_card_tag(
        path: .init(card_id: cardId),
        body: .json(.init(name: name))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }

  /// Removes a tag from a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - tagId: The tag identifier.
  /// - Returns: The deleted tag ID.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card or tag does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func removeCardTag(cardId: Int, tagId: Int) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_card_tag(
        path: .init(card_id: cardId, tag_id: tagId)
      )
    }
    let body = try decodeResponse(response.toCase(), notFoundResource: ("tag", tagId)) {
      try $0.json
    }
    return body.id
  }
}
