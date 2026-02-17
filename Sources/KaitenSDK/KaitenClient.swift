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

    /// Standard response case from an OpenAPI-generated Output enum.
    /// Used by `handleResponse` to eliminate switch boilerplate.
    enum ResponseCase<OKBody> {
        case ok(OKBody)
        case unauthorized
        case forbidden
        case notFound
        case undocumented(statusCode: Int)
    }

    /// Handles a standard response by extracting the ok body or throwing the appropriate error.
    /// The `ok` closure receives the body and should extract the JSON value.
    private func handleResponse<OKBody, JSONBody, T>(
        _ responseCase: ResponseCase<OKBody>,
        notFoundResource: (name: String, id: Int)? = nil,
        extract: (OKBody) -> JSONBody,
        transform: (JSONBody) throws(KaitenError) -> T
    ) throws(KaitenError) -> T {
        switch responseCase {
        case .ok(let body):
            return try transform(extract(body))
        case .unauthorized:
            throw .unauthorized
        case .forbidden:
            throw .unexpectedResponse(statusCode: 403)
        case .notFound:
            if let res = notFoundResource {
                throw .notFound(resource: res.name, id: res.id)
            }
            throw .unexpectedResponse(statusCode: 404)
        case .undocumented(let code):
            throw .unexpectedResponse(statusCode: code)
        }
    }

    /// Convenience: handle response, decode JSON body.
    private func decodeResponse<OKBody, T: Sendable>(
        _ responseCase: ResponseCase<OKBody>,
        notFoundResource: (name: String, id: Int)? = nil,
        json: (OKBody) throws -> T
    ) throws(KaitenError) -> T {
        switch responseCase {
        case .ok(let body):
            return try decode { try json(body) }
        case .unauthorized:
            throw .unauthorized
        case .forbidden:
            throw .unexpectedResponse(statusCode: 403)
        case .notFound:
            if let res = notFoundResource {
                throw .notFound(resource: res.name, id: res.id)
            }
            throw .unexpectedResponse(statusCode: 404)
        case .undocumented(let code):
            throw .unexpectedResponse(statusCode: code)
        }
    }

    // MARK: - Cards

    /// Returns a page of cards for the given board.
    public func listCards(boardId: Int, offset: Int = 0, limit: Int = 100) async throws(KaitenError) -> Page<Components.Schemas.Card> {
        let response: Operations.get_cards.Output
        do {
            response = try await client.get_cards(query: .init(board_id: boardId, offset: offset, limit: limit))
        } catch let error as ClientError where error.response?.status == .ok {
            // Kaiten returns HTTP 200 with empty body when a board has no cards (#84).
            return Page(items: [], offset: offset, limit: limit)
        } catch let error as KaitenError {
            throw error
        } catch {
            throw .networkError(underlying: error)
        }
        let items: [Components.Schemas.Card] = try decodeResponse(response.toCase()) { try $0.json }
        return Page(items: items, offset: offset, limit: limit)
    }

    /// Fetches a single card by its identifier.
    public func getCard(id: Int) async throws(KaitenError) -> Components.Schemas.Card {
        let response = try await call { try await client.get_card(path: .init(card_id: id)) }
        return try decodeResponse(response.toCase(), notFoundResource: ("card", id)) { try $0.json }
    }

    // MARK: - Card Members

    /// Fetches the list of members for a given card.
    public func getCardMembers(cardId: Int) async throws(KaitenError) -> [Components.Schemas.MemberDetailed] {
        let response = try await call { try await client.retrieve_list_of_card_members(path: .init(card_id: cardId)) }
        return try decodeResponse(response.toCase()) { try $0.json }
    }

    /// Fetches comments for a card.
    public func getCardComments(cardId: Int) async throws(KaitenError) -> [Components.Schemas.Comment] {
        let response = try await call { try await client.retrieve_card_comments(path: .init(card_id: cardId)) }
        return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
    }
}

// MARK: - Custom Properties

extension KaitenClient {
    /// List all custom property definitions for the company.
    public func listCustomProperties(offset: Int = 0, limit: Int = 100) async throws(KaitenError) -> Page<Components.Schemas.CustomProperty> {
        let response = try await call { try await client.get_list_of_properties(query: .init(offset: offset, limit: limit)) }
        let items: [Components.Schemas.CustomProperty] = try decodeResponse(response.toCase()) { try $0.json }
        return Page(items: items, offset: offset, limit: limit)
    }

    /// Get a single custom property definition.
    public func getCustomProperty(id: Int) async throws(KaitenError) -> Components.Schemas.CustomProperty {
        let response = try await call { try await client.get_property(path: .init(id: id)) }
        return try decodeResponse(response.toCase(), notFoundResource: ("customProperty", id)) { try $0.json }
    }
}

// MARK: - Boards

extension KaitenClient {
    /// Fetches a board by its identifier.
    public func getBoard(id: Int) async throws(KaitenError) -> Components.Schemas.Board {
        let response = try await call { try await client.get_board(path: .init(id: id)) }
        return try decodeResponse(response.toCase(), notFoundResource: ("board", id)) { try $0.json }
    }

    /// Fetches columns for a board.
    public func getBoardColumns(boardId: Int) async throws(KaitenError) -> [Components.Schemas.Column] {
        let response = try await call { try await client.get_list_of_columns(path: .init(board_id: boardId)) }
        return try decodeResponse(response.toCase(), notFoundResource: ("board", boardId)) { try $0.json }
    }

    /// Fetches lanes for a board.
    public func getBoardLanes(boardId: Int) async throws(KaitenError) -> [Components.Schemas.Lane] {
        let response = try await call { try await client.get_list_of_lanes(path: .init(board_id: boardId)) }
        return try decodeResponse(response.toCase(), notFoundResource: ("board", boardId)) { try $0.json }
    }
}

// MARK: - Spaces

extension KaitenClient {
    /// Lists all spaces.
    public func listSpaces() async throws(KaitenError) -> [Components.Schemas.Space] {
        let response = try await call { try await client.retrieve_list_of_spaces() }
        return try decodeResponse(response.toCase()) { try $0.json }
    }

    /// Lists boards in a space.
    public func listBoards(spaceId: Int) async throws(KaitenError) -> [Components.Schemas.BoardInSpace] {
        let response = try await call { try await client.get_list_of_boards(path: .init(space_id: spaceId)) }
        return try decodeResponse(response.toCase(), notFoundResource: ("space", spaceId)) { try $0.json }
    }
}

// MARK: - Helpers

extension Optional {
    func orThrow(_ error: @autoclosure () -> KaitenError) throws(KaitenError) -> Wrapped {
        guard let self else { throw error() }
        return self
    }
}
