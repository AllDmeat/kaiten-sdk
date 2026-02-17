import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

/// Main entry point for the Kaiten SDK.
///
/// Accepts explicit `baseURL` and `token` parameters.
public struct KaitenClient: Sendable {
    private let client: Client

    // MARK: - Initialization

    /// Creates a client with a custom transport (for testing).
    ///
    /// - Parameters:
    ///   - baseURL: Full Kaiten API base URL (e.g. `https://mycompany.kaiten.ru/api/latest`).
    ///   - token: API bearer token.
    ///   - transport: Custom `ClientTransport` implementation.
    /// - Throws: ``KaitenError/invalidURL(_:)`` if `baseURL` cannot be parsed.
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

    /// Creates a new Kaiten API client.
    ///
    /// - Parameters:
    ///   - baseURL: Full Kaiten API base URL (e.g. `https://mycompany.kaiten.ru/api/latest`).
    ///   - token: API bearer token.
    /// - Throws: ``KaitenError/invalidURL(_:)`` if `baseURL` cannot be parsed.
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

    /// Executes an API call for list endpoints.
    /// Returns `nil` when Kaiten returns HTTP 200 with an empty body (no JSON),
    /// allowing callers to fall back to an empty array.
    private func callList<T>(_ operation: () async throws -> T) async throws(KaitenError) -> T? {
        do {
            return try await operation()
        } catch let error as ClientError where error.response?.status == .ok {
            return nil
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

    /// Filters for listing cards.
    ///
    /// All fields are optional. Only non-nil values are sent to the API.
    /// Every query parameter supported by GET /cards is exposed here.
    public struct CardFilter: Sendable {
        // MARK: - Date filters

        /// Filter cards created before this date.
        public var createdBefore: Date?
        /// Filter cards created after this date.
        public var createdAfter: Date?
        /// Filter cards updated before this date.
        public var updatedBefore: Date?
        /// Filter cards updated after this date.
        public var updatedAfter: Date?
        /// Filter cards first moved to in-progress after this date.
        public var firstMovedInProgressAfter: Date?
        /// Filter cards first moved to in-progress before this date.
        public var firstMovedInProgressBefore: Date?
        /// Filter cards last moved to done after this date.
        public var lastMovedToDoneAtAfter: Date?
        /// Filter cards last moved to done before this date.
        public var lastMovedToDoneAtBefore: Date?
        /// Filter cards with due date after this date.
        public var dueDateAfter: Date?
        /// Filter cards with due date before this date.
        public var dueDateBefore: Date?

        // MARK: - Text search

        /// Text search query.
        public var query: String?
        /// Comma-separated fields to search in.
        public var searchFields: String?

        // MARK: - Tags

        /// Filter by tag name.
        public var tag: String?
        /// Comma-separated tag IDs.
        public var tagIds: String?

        // MARK: - ID filters

        /// Filter by card type ID.
        public var typeId: Int?
        /// Comma-separated card type IDs.
        public var typeIds: String?
        /// Comma-separated member user IDs.
        public var memberIds: String?
        /// Filter by owner user ID.
        public var ownerId: Int?
        /// Comma-separated owner user IDs.
        public var ownerIds: String?
        /// Filter by responsible user ID.
        public var responsibleId: Int?
        /// Comma-separated responsible user IDs.
        public var responsibleIds: String?
        /// Comma-separated column IDs.
        public var columnIds: String?
        /// Filter by space ID.
        public var spaceId: Int?
        /// Filter by external ID.
        public var externalId: String?
        /// Comma-separated organization IDs.
        public var organizationsIds: String?

        // MARK: - Exclude filters

        /// Comma-separated board IDs to exclude.
        public var excludeBoardIds: String?
        /// Comma-separated lane IDs to exclude.
        public var excludeLaneIds: String?
        /// Comma-separated column IDs to exclude.
        public var excludeColumnIds: String?
        /// Comma-separated owner IDs to exclude.
        public var excludeOwnerIds: String?
        /// Comma-separated card IDs to exclude.
        public var excludeCardIds: String?

        // MARK: - State filters

        /// Card condition: 1 = on board, 2 = archived.
        public var condition: Int?
        /// Comma-separated states: 1 = queued, 2 = in progress, 3 = done.
        public var states: String?
        /// Filter by archived status.
        public var archived: Bool?
        /// Filter ASAP cards.
        public var asap: Bool?
        /// Filter overdue cards.
        public var overdue: Bool?
        /// Filter cards done on time.
        public var doneOnTime: Bool?
        /// Filter cards that have a due date.
        public var withDueDate: Bool?
        /// Filter service desk request cards.
        public var isRequest: Bool?

        // MARK: - Sorting

        /// Field to order by.
        public var orderBy: String?
        /// Order direction: asc or desc.
        public var orderDirection: String?
        /// Space ID for ordering context.
        public var orderSpaceId: Int?

        // MARK: - Extra

        /// Comma-separated additional fields to include.
        public var additionalCardFields: String?

        /// Creates a new card filter with all fields defaulting to `nil`.
        public init(
            createdBefore: Date? = nil,
            createdAfter: Date? = nil,
            updatedBefore: Date? = nil,
            updatedAfter: Date? = nil,
            firstMovedInProgressAfter: Date? = nil,
            firstMovedInProgressBefore: Date? = nil,
            lastMovedToDoneAtAfter: Date? = nil,
            lastMovedToDoneAtBefore: Date? = nil,
            dueDateAfter: Date? = nil,
            dueDateBefore: Date? = nil,
            query: String? = nil,
            searchFields: String? = nil,
            tag: String? = nil,
            tagIds: String? = nil,
            typeId: Int? = nil,
            typeIds: String? = nil,
            memberIds: String? = nil,
            ownerId: Int? = nil,
            ownerIds: String? = nil,
            responsibleId: Int? = nil,
            responsibleIds: String? = nil,
            columnIds: String? = nil,
            spaceId: Int? = nil,
            externalId: String? = nil,
            organizationsIds: String? = nil,
            excludeBoardIds: String? = nil,
            excludeLaneIds: String? = nil,
            excludeColumnIds: String? = nil,
            excludeOwnerIds: String? = nil,
            excludeCardIds: String? = nil,
            condition: Int? = nil,
            states: String? = nil,
            archived: Bool? = nil,
            asap: Bool? = nil,
            overdue: Bool? = nil,
            doneOnTime: Bool? = nil,
            withDueDate: Bool? = nil,
            isRequest: Bool? = nil,
            orderBy: String? = nil,
            orderDirection: String? = nil,
            orderSpaceId: Int? = nil,
            additionalCardFields: String? = nil
        ) {
            self.createdBefore = createdBefore
            self.createdAfter = createdAfter
            self.updatedBefore = updatedBefore
            self.updatedAfter = updatedAfter
            self.firstMovedInProgressAfter = firstMovedInProgressAfter
            self.firstMovedInProgressBefore = firstMovedInProgressBefore
            self.lastMovedToDoneAtAfter = lastMovedToDoneAtAfter
            self.lastMovedToDoneAtBefore = lastMovedToDoneAtBefore
            self.dueDateAfter = dueDateAfter
            self.dueDateBefore = dueDateBefore
            self.query = query
            self.searchFields = searchFields
            self.tag = tag
            self.tagIds = tagIds
            self.typeId = typeId
            self.typeIds = typeIds
            self.memberIds = memberIds
            self.ownerId = ownerId
            self.ownerIds = ownerIds
            self.responsibleId = responsibleId
            self.responsibleIds = responsibleIds
            self.columnIds = columnIds
            self.spaceId = spaceId
            self.externalId = externalId
            self.organizationsIds = organizationsIds
            self.excludeBoardIds = excludeBoardIds
            self.excludeLaneIds = excludeLaneIds
            self.excludeColumnIds = excludeColumnIds
            self.excludeOwnerIds = excludeOwnerIds
            self.excludeCardIds = excludeCardIds
            self.condition = condition
            self.states = states
            self.archived = archived
            self.asap = asap
            self.overdue = overdue
            self.doneOnTime = doneOnTime
            self.withDueDate = withDueDate
            self.isRequest = isRequest
            self.orderBy = orderBy
            self.orderDirection = orderDirection
            self.orderSpaceId = orderSpaceId
            self.additionalCardFields = additionalCardFields
        }
    }

    /// Returns a page of cards, optionally filtered.
    ///
    /// - Parameters:
    ///   - boardId: Filter by board identifier (optional).
    ///   - columnId: Filter by column identifier (optional).
    ///   - laneId: Filter by lane identifier (optional).
    ///   - offset: Number of cards to skip (default `0`).
    ///   - limit: Maximum number of cards to return (default `100`).
    ///   - filter: Optional ``CardFilter`` with additional query parameters.
    /// - Returns: A ``Page`` of cards. Returns an empty page when no cards match.
    /// - Throws: ``KaitenError``
    public func listCards(boardId: Int? = nil, columnId: Int? = nil, laneId: Int? = nil, offset: Int = 0, limit: Int = 100, filter: CardFilter? = nil) async throws(KaitenError) -> Page<Components.Schemas.Card> {
        let f = filter
        let queryParams = Operations.get_cards.Input.Query(
            board_id: boardId,
            column_id: columnId,
            lane_id: laneId,
            offset: offset,
            limit: limit,
            created_before: f?.createdBefore,
            created_after: f?.createdAfter,
            updated_before: f?.updatedBefore,
            updated_after: f?.updatedAfter,
            first_moved_in_progress_after: f?.firstMovedInProgressAfter,
            first_moved_in_progress_before: f?.firstMovedInProgressBefore,
            last_moved_to_done_at_after: f?.lastMovedToDoneAtAfter,
            last_moved_to_done_at_before: f?.lastMovedToDoneAtBefore,
            due_date_after: f?.dueDateAfter,
            due_date_before: f?.dueDateBefore,
            query: f?.query,
            search_fields: f?.searchFields,
            tag: f?.tag,
            tag_ids: f?.tagIds,
            type_id: f?.typeId,
            type_ids: f?.typeIds,
            member_ids: f?.memberIds,
            owner_id: f?.ownerId,
            owner_ids: f?.ownerIds,
            responsible_id: f?.responsibleId,
            responsible_ids: f?.responsibleIds,
            column_ids: f?.columnIds,
            space_id: f?.spaceId,
            external_id: f?.externalId,
            organizations_ids: f?.organizationsIds,
            exclude_board_ids: f?.excludeBoardIds,
            exclude_lane_ids: f?.excludeLaneIds,
            exclude_column_ids: f?.excludeColumnIds,
            exclude_owner_ids: f?.excludeOwnerIds,
            exclude_card_ids: f?.excludeCardIds,
            condition: f?.condition,
            states: f?.states,
            archived: f?.archived,
            asap: f?.asap,
            overdue: f?.overdue,
            done_on_time: f?.doneOnTime,
            with_due_date: f?.withDueDate,
            is_request: f?.isRequest,
            order_by: f?.orderBy,
            order_direction: f?.orderDirection,
            order_space_id: f?.orderSpaceId,
            additional_card_fields: f?.additionalCardFields
        )
        guard let response = try await callList({ try await client.get_cards(query: queryParams) }) else {
            return Page(items: [], offset: offset, limit: limit)
        }
        let items: [Components.Schemas.Card] = try decodeResponse(response.toCase()) { try $0.json }
        return Page(items: items, offset: offset, limit: limit)
    }

    /// Fetches a single card by its identifier.
    ///
    /// - Parameter id: The card identifier.
    /// - Returns: The full card object with all fields including custom properties.
    /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card does not exist.
    public func getCard(id: Int) async throws(KaitenError) -> Components.Schemas.Card {
        let response = try await call { try await client.get_card(path: .init(card_id: id)) }
        return try decodeResponse(response.toCase(), notFoundResource: ("card", id)) { try $0.json }
    }

    // MARK: - Card Members

    /// Fetches the list of members assigned to a card.
    ///
    /// - Parameter cardId: The card identifier.
    /// - Returns: An array of detailed member objects. Returns an empty array if no members are assigned.
    /// - Throws: ``KaitenError``
    public func getCardMembers(cardId: Int) async throws(KaitenError) -> [Components.Schemas.MemberDetailed] {
        guard let response = try await callList({ try await client.retrieve_list_of_card_members(path: .init(card_id: cardId)) }) else {
            return []
        }
        return try decodeResponse(response.toCase()) { try $0.json }
    }

    /// Fetches all comments on a card.
    ///
    /// - Parameter cardId: The card identifier.
    /// - Returns: An array of comments. Returns an empty array if the card has no comments.
    /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card does not exist.
    public func getCardComments(cardId: Int) async throws(KaitenError) -> [Components.Schemas.Comment] {
        guard let response = try await callList({ try await client.retrieve_card_comments(path: .init(card_id: cardId)) }) else {
            return []
        }
        return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
    }
}

// MARK: - Custom Properties

extension KaitenClient {
    /// Lists all custom property definitions for the company.
    ///
    /// Custom properties are company-wide field definitions (e.g. "Team", "Platform")
    /// that can be attached to cards.
    ///
    /// - Parameters:
    ///   - offset: Number of properties to skip (default `0`).
    ///   - limit: Maximum number of properties to return (default `100`).
    ///   - query: Text search query to filter properties by name.
    ///   - includeValues: Include property values in the response.
    ///   - includeAuthor: Include author details in the response.
    ///   - compact: Return compact representation.
    ///   - loadByIds: Load properties by IDs (use with `ids`).
    ///   - ids: Array of property IDs to load (requires `loadByIds: true`).
    ///   - orderBy: Field to order by.
    ///   - orderDirection: Order direction: asc or desc.
    /// - Returns: A ``Page`` of custom property definitions.
    /// - Throws: ``KaitenError``
    public func listCustomProperties(
        offset: Int = 0,
        limit: Int = 100,
        query: String? = nil,
        includeValues: Bool? = nil,
        includeAuthor: Bool? = nil,
        compact: Bool? = nil,
        loadByIds: Bool? = nil,
        ids: [Int]? = nil,
        orderBy: String? = nil,
        orderDirection: String? = nil
    ) async throws(KaitenError) -> Page<Components.Schemas.CustomProperty> {
        guard let response = try await callList({ try await client.get_list_of_properties(query: .init(offset: offset, limit: limit, include_values: includeValues, include_author: includeAuthor, compact: compact, load_by_ids: loadByIds, ids: ids, order_by: orderBy, order_direction: orderDirection, query: query)) }) else {
            return Page(items: [], offset: offset, limit: limit)
        }
        let items: [Components.Schemas.CustomProperty] = try decodeResponse(response.toCase()) { try $0.json }
        return Page(items: items, offset: offset, limit: limit)
    }

    /// Fetches a single custom property definition by its identifier.
    ///
    /// - Parameter id: The custom property identifier.
    /// - Returns: The custom property definition.
    /// - Throws: ``KaitenError/notFound(resource:id:)`` if the property does not exist.
    public func getCustomProperty(id: Int) async throws(KaitenError) -> Components.Schemas.CustomProperty {
        let response = try await call { try await client.get_property(path: .init(id: id)) }
        return try decodeResponse(response.toCase(), notFoundResource: ("customProperty", id)) { try $0.json }
    }
}

// MARK: - Boards

extension KaitenClient {
    /// Fetches a board by its identifier.
    ///
    /// Returns the full board object including columns, lanes, and cards.
    ///
    /// - Parameter id: The board identifier.
    /// - Returns: The full board object.
    /// - Throws: ``KaitenError/notFound(resource:id:)`` if the board does not exist.
    public func getBoard(id: Int) async throws(KaitenError) -> Components.Schemas.Board {
        let response = try await call { try await client.get_board(path: .init(id: id)) }
        return try decodeResponse(response.toCase(), notFoundResource: ("board", id)) { try $0.json }
    }

    /// Fetches all columns for a board.
    ///
    /// - Parameter boardId: The board identifier.
    /// - Returns: An array of columns. Returns an empty array if the board has no columns.
    /// - Throws: ``KaitenError/notFound(resource:id:)`` if the board does not exist.
    public func getBoardColumns(boardId: Int) async throws(KaitenError) -> [Components.Schemas.Column] {
        guard let response = try await callList({ try await client.get_list_of_columns(path: .init(board_id: boardId)) }) else {
            return []
        }
        return try decodeResponse(response.toCase(), notFoundResource: ("board", boardId)) { try $0.json }
    }

    /// Fetches all lanes (horizontal swimlanes) for a board.
    ///
    /// - Parameters:
    ///   - boardId: The board identifier.
    ///   - condition: Optional lane condition filter: 1 = live, 2 = archived, 3 = deleted.
    /// - Returns: An array of lanes. Returns an empty array if the board has no lanes.
    /// - Throws: ``KaitenError/notFound(resource:id:)`` if the board does not exist.
    public func getBoardLanes(boardId: Int, condition: Int? = nil) async throws(KaitenError) -> [Components.Schemas.Lane] {
        guard let response = try await callList({ try await client.get_list_of_lanes(path: .init(board_id: boardId), query: .init(condition: condition)) }) else {
            return []
        }
        return try decodeResponse(response.toCase(), notFoundResource: ("board", boardId)) { try $0.json }
    }
}

// MARK: - Spaces

extension KaitenClient {
    /// Lists all spaces visible to the authenticated user.
    ///
    /// - Returns: An array of spaces. Returns an empty array if no spaces are available.
    /// - Throws: ``KaitenError``
    public func listSpaces() async throws(KaitenError) -> [Components.Schemas.Space] {
        guard let response = try await callList({ try await client.retrieve_list_of_spaces() }) else {
            return []
        }
        return try decodeResponse(response.toCase()) { try $0.json }
    }

    /// Lists all boards within a space.
    ///
    /// - Parameter spaceId: The space identifier.
    /// - Returns: An array of boards. Returns an empty array if the space has no boards.
    /// - Throws: ``KaitenError/notFound(resource:id:)`` if the space does not exist.
    public func listBoards(spaceId: Int) async throws(KaitenError) -> [Components.Schemas.BoardInSpace] {
        guard let response = try await callList({ try await client.get_list_of_boards(path: .init(space_id: spaceId)) }) else {
            return []
        }
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
