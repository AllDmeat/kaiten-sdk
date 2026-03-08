import Foundation
import OpenAPIRuntime

// MARK: - Card Members

extension KaitenClient {
  /// Fetches the list of members assigned to a card.
  ///
  /// - Parameter cardId: The card identifier.
  /// - Returns: An array of detailed member objects. Returns an empty array if no members are assigned.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func getCardMembers(cardId: Int) async throws(KaitenError) -> [Components.Schemas
    .MemberDetailed]
  {
    guard
      let response = try await callList({
        try await client.retrieve_list_of_card_members(path: .init(card_id: cardId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Adds a member to a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - userId: The user identifier to add.
  /// - Returns: The added member details.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func addCardMember(cardId: Int, userId: Int) async throws(KaitenError)
    -> Components.Schemas.MemberDetailed
  {
    let response = try await call {
      try await client.add_card_member(
        path: .init(card_id: cardId),
        body: .json(.init(user_id: userId))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }

  /// Updates a card member's role.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - userId: The user identifier.
  ///   - type: The member role type.
  /// - Returns: The updated card member role.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the member does not exist on the card.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func updateCardMemberRole(cardId: Int, userId: Int, type: CardMemberRoleType)
    async throws(KaitenError)
    -> Components.Schemas.CardMemberRole
  {
    let response = try await call {
      try await client.update_card_member_role(
        path: .init(card_id: cardId, id: userId),
        body: .json(.init(_type: type.rawValue))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("member", userId)) {
      try $0.json
    }
  }

  /// Removes a member from a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - userId: The user identifier to remove.
  /// - Returns: The removed user ID.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the member does not exist on the card.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func removeCardMember(cardId: Int, userId: Int) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_card_member(path: .init(card_id: cardId, id: userId))
    }
    let result: Components.Schemas.DeletedMemberResponse = try decodeResponse(
      response.toCase(), notFoundResource: ("member", userId)
    ) { try $0.json }
    return result.id
  }
}
