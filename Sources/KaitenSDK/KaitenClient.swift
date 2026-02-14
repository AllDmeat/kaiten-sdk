import Configuration
import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

/// Main entry point for the Kaiten SDK.
///
/// Reads `KAITEN_URL` and `KAITEN_TOKEN` from environment variables.
/// Fails fast if either is missing.
public struct KaitenClient: Sendable {
    private let client: Client
    private let config: KaitenConfiguration

    /// Creates a new ``KaitenClient``.
    ///
    /// - Throws: ``KaitenError/missingConfiguration(_:)`` if `KAITEN_URL` or `KAITEN_TOKEN`
    ///   are not found in the environment.
    // MARK: - Cards

    /// Returns all cards for the given board.
    ///
    /// - Parameter boardId: The board to fetch cards from.
    /// - Returns: An array of ``Components/Schemas/Card``.
    /// - Throws: ``KaitenError/unauthorized`` or ``KaitenError/unexpectedResponse(statusCode:)``.
    public func listCards(boardId: Int) async throws -> [Components.Schemas.Card] {
        let response = try await client.get_cards(query: .init(board_id: boardId))
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .unauthorized:
            throw KaitenError.unauthorized
        case .undocumented(statusCode: let code, _):
            throw KaitenError.unexpectedResponse(statusCode: code)
        }
    }

    // MARK: - Initialization

    /// Internal initializer for testing with a custom transport.
    init(transport: any ClientTransport) throws {
        self.config = try KaitenConfiguration.resolve()
        let url = try URL(string: config.baseURL)
            .orThrow(KaitenError.invalidURL(config.baseURL))
        self.client = Client(
            serverURL: url,
            transport: transport,
            middlewares: [
                AuthenticationMiddleware(token: config.token),
                RetryMiddleware(),
            ]
        )
    }

    public init() throws {
        self.config = try KaitenConfiguration.resolve()

        let url = try URL(string: config.baseURL)
            .orThrow(KaitenError.invalidURL(config.baseURL))

        self.client = Client(
            serverURL: url,
            transport: URLSessionTransport(),
            middlewares: [
                AuthenticationMiddleware(token: config.token),
                RetryMiddleware(),
            ]
        )
    }

    // MARK: - Cards

    /// Fetches a single card by its identifier.
    ///
    /// - Parameter id: The card identifier.
    /// - Returns: The ``Components.Schemas.Card`` for the given id.
    /// - Throws: ``KaitenError`` on failure.
    public func getCard(id: Int) async throws -> Components.Schemas.Card {
        let response = try await client.get_card(path: .init(card_id: id))
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .unauthorized(_):
            throw KaitenError.unauthorized
        case .notFound(_):
            throw KaitenError.notFound(resource: "card", id: id)
        case .undocumented(statusCode: let code, _):
            throw KaitenError.unexpectedResponse(statusCode: code)
        }
    }

    // MARK: - Card Members

    /// Fetches the list of members for a given card.
    ///
    /// - Parameter cardId: The card identifier.
    /// - Returns: An array of ``Components.Schemas.MemberDetailed``.
    /// - Throws: ``KaitenError`` on failure.
    public func getCardMembers(cardId: Int) async throws -> [Components.Schemas.MemberDetailed] {
        let response = try await client.retrieve_list_of_card_members(path: .init(card_id: cardId))
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .unauthorized(_):
            throw KaitenError.unauthorized
        case .forbidden(_):
            throw KaitenError.unexpectedResponse(statusCode: 403)
        case .undocumented(statusCode: let code, _):
            throw KaitenError.unexpectedResponse(statusCode: code)
        }
    }
}

// MARK: - Configuration

struct KaitenConfiguration: Sendable {
    let baseURL: String
    let token: String

    static func resolve() throws -> KaitenConfiguration {
        let config = ConfigReader(providers: [
            EnvironmentVariablesProvider(),
        ])

        guard let url: String = config.string(forKey: "KAITEN_URL") else {
            throw KaitenError.missingConfiguration("KAITEN_URL")
        }
        guard let token: String = config.string(forKey: "KAITEN_TOKEN") else {
            throw KaitenError.missingConfiguration("KAITEN_TOKEN")
        }

        return KaitenConfiguration(baseURL: url, token: token)
    }
}

// MARK: - Custom Properties

extension KaitenClient {
    /// List all custom property definitions for the company.
    public func listCustomProperties() async throws -> [Components.Schemas.CustomProperty] {
        let response = try await client.get_list_of_properties()
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .unauthorized(_):
            throw KaitenError.unauthorized
        case .forbidden(_):
            throw KaitenError.unexpectedResponse(statusCode: 403)
        case .undocumented(statusCode: let code, _):
            throw KaitenError.unexpectedResponse(statusCode: code)
        }
    }

    /// Get a single custom property definition.
    public func getCustomProperty(id: Int) async throws -> Components.Schemas.CustomProperty {
        let response = try await client.get_property(path: .init(id: id))
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .unauthorized(_):
            throw KaitenError.unauthorized
        case .forbidden(_):
            throw KaitenError.unexpectedResponse(statusCode: 403)
        case .notFound(_):
            throw KaitenError.notFound(resource: "customProperty", id: id)
        case .undocumented(statusCode: let code, _):
            throw KaitenError.unexpectedResponse(statusCode: code)
        }
    }
}

// MARK: - Boards

extension KaitenClient {
    /// Fetches a board by its identifier.
    public func getBoard(id: Int) async throws -> Components.Schemas.Board {
        let response = try await client.get_board(path: .init(id: id))
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .unauthorized(_):
            throw KaitenError.unauthorized
        case .forbidden(_):
            throw KaitenError.unexpectedResponse(statusCode: 403)
        case .notFound(_):
            throw KaitenError.notFound(resource: "board", id: id)
        case .undocumented(statusCode: let code, _):
            throw KaitenError.unexpectedResponse(statusCode: code)
        }
    }

    /// Fetches columns for a board.
    public func getBoardColumns(boardId: Int) async throws -> [Components.Schemas.Column] {
        let response = try await client.get_list_of_columns(path: .init(board_id: boardId))
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .unauthorized(_):
            throw KaitenError.unauthorized
        case .forbidden(_):
            throw KaitenError.unexpectedResponse(statusCode: 403)
        case .notFound(_):
            throw KaitenError.notFound(resource: "board", id: boardId)
        case .undocumented(statusCode: let code, _):
            throw KaitenError.unexpectedResponse(statusCode: code)
        }
    }

    /// Fetches lanes for a board.
    public func getBoardLanes(boardId: Int) async throws -> [Components.Schemas.Lane] {
        let response = try await client.get_list_of_lanes(path: .init(board_id: boardId))
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .unauthorized(_):
            throw KaitenError.unauthorized
        case .forbidden(_):
            throw KaitenError.unexpectedResponse(statusCode: 403)
        case .notFound(_):
            throw KaitenError.notFound(resource: "board", id: boardId)
        case .undocumented(statusCode: let code, _):
            throw KaitenError.unexpectedResponse(statusCode: code)
        }
    }
}

// MARK: - Spaces

extension KaitenClient {
    /// Lists all spaces.
    public func listSpaces() async throws -> [Components.Schemas.Space] {
        let response = try await client.retrieve_list_of_spaces()
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .unauthorized(_):
            throw KaitenError.unauthorized
        case .undocumented(statusCode: let code, _):
            throw KaitenError.unexpectedResponse(statusCode: code)
        }
    }

    /// Lists boards in a space.
    public func listBoards(spaceId: Int) async throws -> [Components.Schemas.BoardInSpace] {
        let response = try await client.get_list_of_boards(path: .init(space_id: spaceId))
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .unauthorized(_):
            throw KaitenError.unauthorized
        case .forbidden(_):
            throw KaitenError.unexpectedResponse(statusCode: 403)
        case .undocumented(statusCode: let code, _):
            throw KaitenError.unexpectedResponse(statusCode: code)
        }
    }
}

// MARK: - Errors

// MARK: - Helpers

extension Optional {
    func orThrow(_ error: @autoclosure () -> some Error) throws -> Wrapped {
        guard let self else { throw error() }
        return self
    }
}
