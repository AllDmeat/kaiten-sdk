import Foundation
import OpenAPIRuntime

// MARK: - Users

extension KaitenClient {
  /// Lists users in the company.
  ///
  /// - Parameters:
  ///   - type: Type of users to return.
  ///   - query: Search query.
  ///   - ids: Comma-separated user IDs.
  ///   - limit: Maximum number of users (max 100).
  ///   - offset: Pagination offset.
  ///   - includeInactive: Include inactive users.
  /// - Returns: An array of users.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for undocumented HTTP status codes.
  public func listUsers(
    type: String? = nil,
    query: String? = nil,
    ids: String? = nil,
    limit: Int? = nil,
    offset: Int? = nil,
    includeInactive: Bool? = nil
  ) async throws(KaitenError) -> [Components.Schemas.User] {
    guard
      let response = try await callList({
        try await client.retrieve_list_of_users(
          query: .init(
            _type: type,
            query: query,
            ids: ids,
            limit: limit,
            offset: offset,
            include_inactive: includeInactive
          )
        )
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Retrieves the currently authenticated user.
  ///
  /// - Returns: The current user.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for undocumented HTTP status codes.
  public func getCurrentUser() async throws(KaitenError) -> Components.Schemas.User {
    let response = try await call { try await client.retrieve_current_user() }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}
