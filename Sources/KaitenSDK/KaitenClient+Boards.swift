import Foundation
import OpenAPIRuntime

// MARK: - Boards

extension KaitenClient {
  /// Fetches a board by its identifier.
  ///
  /// Returns the full board object including columns, lanes, and cards.
  ///
  /// - Parameter id: The board identifier.
  /// - Returns: The full board object.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the board does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func getBoard(id: Int) async throws(KaitenError) -> Components.Schemas.Board {
    let response = try await call { try await client.get_board(path: .init(id: id)) }
    return try decodeResponse(response.toCase(), notFoundResource: ("board", id)) { try $0.json }
  }

  /// Lists all boards within a space.
  ///
  /// - Parameter spaceId: The space identifier.
  /// - Returns: An array of boards. Returns an empty array if the space has no boards.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the space does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listBoards(spaceId: Int) async throws(KaitenError) -> [Components.Schemas
    .BoardInSpace]
  {
    guard
      let response = try await callList({
        try await client.get_list_of_boards(path: .init(space_id: spaceId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("space", spaceId)) {
      try $0.json
    }
  }

  /// Creates a new board in a space.
  ///
  /// - Parameters:
  ///   - spaceId: The space identifier.
  ///   - title: The board title.
  ///   - description: An optional board description.
  ///   - sortOrder: An optional sort order.
  ///   - externalId: An optional external identifier.
  /// - Returns: The created board.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the space does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func createBoard(
    spaceId: Int,
    title: String,
    description: String? = nil,
    sortOrder: Double? = nil,
    externalId: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.Board {
    let response = try await call {
      try await client.create_board(
        path: .init(space_id: spaceId),
        body: .json(
          .init(
            title: title,
            description: description,
            sort_order: sortOrder,
            external_id: externalId
          )))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("space", spaceId)
    ) { try $0.json }
  }

  /// Updates a board.
  ///
  /// - Parameters:
  ///   - spaceId: The space identifier.
  ///   - id: The board identifier.
  ///   - title: The updated title.
  ///   - description: The updated description.
  ///   - sortOrder: The updated sort order.
  ///   - externalId: The updated external identifier.
  /// - Returns: The updated board.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the board does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func updateBoard(
    spaceId: Int,
    id: Int,
    title: String? = nil,
    description: String? = nil,
    sortOrder: Double? = nil,
    externalId: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.Board {
    let response = try await call {
      try await client.update_board(
        path: .init(space_id: spaceId, id: id),
        body: .json(
          .init(
            title: title,
            description: description,
            sort_order: sortOrder,
            external_id: externalId
          )))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("board", id)
    ) { try $0.json }
  }
}
