import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

/// Main entry point for the Kaiten SDK.
///
/// Accepts explicit `baseURL` and `token` parameters.
public struct KaitenClient: Sendable {
    private let client: Client

    // MARK: - Initialization

    /// Internal initializer for testing with a custom transport.
    init(baseURL: String, token: String, transport: any ClientTransport) throws(KaitenError) {
        let url = try URL(string: baseURL)
            .orThrow(KaitenError.invalidURL(baseURL))
        self.client = Client(
            serverURL: url,
            transport: transport,
            middlewares: [
                AuthenticationMiddleware(token: token),
                RetryMiddleware(),
            ]
        )
    }

    public init(baseURL: String, token: String) throws(KaitenError) {
        let url = try URL(string: baseURL)
            .orThrow(KaitenError.invalidURL(baseURL))

        self.client = Client(
            serverURL: url,
            transport: URLSessionTransport(),
            middlewares: [
                AuthenticationMiddleware(token: token),
                RetryMiddleware(),
            ]
        )
    }

    // MARK: - Private Helpers

    /// Executes an API call, wrapping non-KaitenError into `.networkError`.
    private func call<T>(_ operation: () async throws -> T) async throws(KaitenError) -> T {
        do {
            return try await operation()
        } catch let error as KaitenError {
            throw error
        } catch {
            throw .networkError(underlying: error)
        }
    }

    /// Decodes a value, wrapping errors into `.decodingError`.
    private func decode<T>(_ extract: () throws -> T) throws(KaitenError) -> T {
        do {
            return try extract()
        } catch {
            throw .decodingError(underlying: error)
        }
    }

    // MARK: - Cards

    /// Returns a page of cards for the given board.
    ///
    /// - Parameters:
    ///   - boardId: The board to fetch cards from.
    ///   - offset: Number of cards to skip (default: 0).
    ///   - limit: Maximum number of cards to return (default/max: 100).
    /// - Returns: A ``Page`` of ``Components/Schemas/Card``.
    /// - Throws: ``KaitenError`` on failure.
    public func listCards(boardId: Int, offset: Int = 0, limit: Int = 100) async throws(KaitenError) -> Page<Components.Schemas.Card> {
        let response: Operations.get_cards.Output
        do {
            response = try await client.get_cards(query: .init(board_id: boardId, offset: offset, limit: limit))
        } catch let error as ClientError where error.response?.status == .ok {
            // Kaiten returns HTTP 200 with empty body when a board has no cards (#84).
            // OpenAPI runtime throws ClientError for missing/empty response body.
            return Page(items: [], offset: offset, limit: limit)
        } catch let error as KaitenError {
            throw error
        } catch {
            throw .networkError(underlying: error)
        }
        switch response {
        case .ok(let ok):
            let items = try decode { try ok.body.json }
            return Page(items: items, offset: offset, limit: limit)
        case .unauthorized:
            throw .unauthorized
        case .undocumented(statusCode: let code, _):
            throw .unexpectedResponse(statusCode: code)
        }
    }

    /// Fetches a single card by its identifier.
    ///
    /// - Parameter id: The card identifier.
    /// - Returns: The ``Components.Schemas.Card`` for the given id.
    /// - Throws: ``KaitenError`` on failure.
    public func getCard(id: Int) async throws(KaitenError) -> Components.Schemas.Card {
        let response = try await call { try await client.get_card(path: .init(card_id: id)) }
        switch response {
        case .ok(let ok):
            return try decode { try ok.body.json }
        case .unauthorized(_):
            throw .unauthorized
        case .notFound(_):
            throw .notFound(resource: "card", id: id)
        case .undocumented(statusCode: let code, _):
            throw .unexpectedResponse(statusCode: code)
        }
    }

    // MARK: - Card Members

    /// Fetches the list of members for a given card.
    ///
    /// - Parameter cardId: The card identifier.
    /// - Returns: An array of ``Components.Schemas.MemberDetailed``.
    /// - Throws: ``KaitenError`` on failure.
    public func getCardMembers(cardId: Int) async throws(KaitenError) -> [Components.Schemas.MemberDetailed] {
        let response = try await call { try await client.retrieve_list_of_card_members(path: .init(card_id: cardId)) }
        switch response {
        case .ok(let ok):
            return try decode { try ok.body.json }
        case .unauthorized(_):
            throw .unauthorized
        case .forbidden(_):
            throw .unexpectedResponse(statusCode: 403)
        case .undocumented(statusCode: let code, _):
            throw .unexpectedResponse(statusCode: code)
        }
    }
}

// MARK: - Custom Properties

extension KaitenClient {
    /// List all custom property definitions for the company.
    public func listCustomProperties() async throws(KaitenError) -> [Components.Schemas.CustomProperty] {
        let response = try await call { try await client.get_list_of_properties() }
        switch response {
        case .ok(let ok):
            return try decode { try ok.body.json }
        case .unauthorized(_):
            throw .unauthorized
        case .forbidden(_):
            throw .unexpectedResponse(statusCode: 403)
        case .undocumented(statusCode: let code, _):
            throw .unexpectedResponse(statusCode: code)
        }
    }

    /// Get a single custom property definition.
    public func getCustomProperty(id: Int) async throws(KaitenError) -> Components.Schemas.CustomProperty {
        let response = try await call { try await client.get_property(path: .init(id: id)) }
        switch response {
        case .ok(let ok):
            return try decode { try ok.body.json }
        case .unauthorized(_):
            throw .unauthorized
        case .forbidden(_):
            throw .unexpectedResponse(statusCode: 403)
        case .notFound(_):
            throw .notFound(resource: "customProperty", id: id)
        case .undocumented(statusCode: let code, _):
            throw .unexpectedResponse(statusCode: code)
        }
    }
}

// MARK: - Boards

extension KaitenClient {
    /// Fetches a board by its identifier.
    public func getBoard(id: Int) async throws(KaitenError) -> Components.Schemas.Board {
        let response = try await call { try await client.get_board(path: .init(id: id)) }
        switch response {
        case .ok(let ok):
            return try decode { try ok.body.json }
        case .unauthorized(_):
            throw .unauthorized
        case .forbidden(_):
            throw .unexpectedResponse(statusCode: 403)
        case .notFound(_):
            throw .notFound(resource: "board", id: id)
        case .undocumented(statusCode: let code, _):
            throw .unexpectedResponse(statusCode: code)
        }
    }

    /// Fetches columns for a board.
    public func getBoardColumns(boardId: Int) async throws(KaitenError) -> [Components.Schemas.Column] {
        let response = try await call { try await client.get_list_of_columns(path: .init(board_id: boardId)) }
        switch response {
        case .ok(let ok):
            return try decode { try ok.body.json }
        case .unauthorized(_):
            throw .unauthorized
        case .forbidden(_):
            throw .unexpectedResponse(statusCode: 403)
        case .notFound(_):
            throw .notFound(resource: "board", id: boardId)
        case .undocumented(statusCode: let code, _):
            throw .unexpectedResponse(statusCode: code)
        }
    }

    /// Fetches lanes for a board.
    public func getBoardLanes(boardId: Int) async throws(KaitenError) -> [Components.Schemas.Lane] {
        let response = try await call { try await client.get_list_of_lanes(path: .init(board_id: boardId)) }
        switch response {
        case .ok(let ok):
            return try decode { try ok.body.json }
        case .unauthorized(_):
            throw .unauthorized
        case .forbidden(_):
            throw .unexpectedResponse(statusCode: 403)
        case .notFound(_):
            throw .notFound(resource: "board", id: boardId)
        case .undocumented(statusCode: let code, _):
            throw .unexpectedResponse(statusCode: code)
        }
    }
}

// MARK: - Spaces

extension KaitenClient {
    /// Lists all spaces.
    public func listSpaces() async throws(KaitenError) -> [Components.Schemas.Space] {
        let response = try await call { try await client.retrieve_list_of_spaces() }
        switch response {
        case .ok(let ok):
            return try decode { try ok.body.json }
        case .unauthorized(_):
            throw .unauthorized
        case .undocumented(statusCode: let code, _):
            throw .unexpectedResponse(statusCode: code)
        }
    }

    /// Lists boards in a space.
    public func listBoards(spaceId: Int) async throws(KaitenError) -> [Components.Schemas.BoardInSpace] {
        let response = try await call { try await client.get_list_of_boards(path: .init(space_id: spaceId)) }
        switch response {
        case .ok(let ok):
            return try decode { try ok.body.json }
        case .unauthorized(_):
            throw .unauthorized
        case .forbidden(_):
            throw .unexpectedResponse(statusCode: 403)
        case .notFound(_):
            throw .notFound(resource: "space", id: spaceId)
        case .undocumented(statusCode: let code, _):
            throw .unexpectedResponse(statusCode: code)
        }
    }
}

// MARK: - Helpers

extension Optional {
    func orThrow(_ error: @autoclosure () -> KaitenError) throws(KaitenError) -> Wrapped {
        guard let self else { throw error() }
        return self
    }
}
