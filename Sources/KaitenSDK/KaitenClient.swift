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
  /// Propagates decoding errors instead of silently returning nil.
  private func callList<T>(_ operation: () async throws -> T) async throws(KaitenError) -> T? {
    do {
      return try await operation()
    } catch let error as ClientError where error.response?.status == .ok {
      // If the underlying error is a schema mismatch (typeMismatch or
      // keyNotFound), the body was valid JSON but didn't match the
      // expected schema — propagate instead of hiding.
      // Other DecodingErrors (dataCorrupted from empty/invalid body)
      // are treated as "no data" and return nil.
      if let decodingError = error.underlyingError as? DecodingError {
        switch decodingError {
        case .typeMismatch, .keyNotFound, .valueNotFound:
          throw .decodingError(underlying: error)
        case .dataCorrupted:
          break  // treat as empty body
        @unknown default:
          throw .decodingError(underlying: error)
        }
      }
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
  /// Standard response case from an OpenAPI-generated Output enum.
  enum ResponseCase<OKBody> {
    case ok(OKBody)
    case unauthorized
    case forbidden
    case notFound
    case undocumented(statusCode: Int)
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
    public let createdBefore: Date?
    /// Filter cards created after this date.
    public let createdAfter: Date?
    /// Filter cards updated before this date.
    public let updatedBefore: Date?
    /// Filter cards updated after this date.
    public let updatedAfter: Date?
    /// Filter cards first moved to in-progress after this date.
    public let firstMovedInProgressAfter: Date?
    /// Filter cards first moved to in-progress before this date.
    public let firstMovedInProgressBefore: Date?
    /// Filter cards last moved to done after this date.
    public let lastMovedToDoneAtAfter: Date?
    /// Filter cards last moved to done before this date.
    public let lastMovedToDoneAtBefore: Date?
    /// Filter cards with due date after this date.
    public let dueDateAfter: Date?
    /// Filter cards with due date before this date.
    public let dueDateBefore: Date?

    // MARK: - Text search

    /// Text search query.
    public let query: String?
    /// Comma-separated fields to search in.
    public let searchFields: String?

    // MARK: - Tags

    /// Filter by tag name.
    public let tag: String?
    /// Comma-separated tag IDs.
    public let tagIds: String?

    // MARK: - ID filters

    /// Filter by card type ID.
    public let typeId: Int?
    /// Comma-separated card type IDs.
    public let typeIds: String?
    /// Comma-separated member user IDs.
    public let memberIds: String?
    /// Filter by owner user ID.
    public let ownerId: Int?
    /// Comma-separated owner user IDs.
    public let ownerIds: String?
    /// Filter by responsible user ID.
    public let responsibleId: Int?
    /// Comma-separated responsible user IDs.
    public let responsibleIds: String?
    /// Comma-separated column IDs.
    public let columnIds: String?
    /// Filter by space ID.
    public let spaceId: Int?
    /// Filter by external ID.
    public let externalId: String?
    /// Comma-separated organization IDs.
    public let organizationsIds: String?

    // MARK: - Exclude filters

    /// Comma-separated board IDs to exclude.
    public let excludeBoardIds: String?
    /// Comma-separated lane IDs to exclude.
    public let excludeLaneIds: String?
    /// Comma-separated column IDs to exclude.
    public let excludeColumnIds: String?
    /// Comma-separated owner IDs to exclude.
    public let excludeOwnerIds: String?
    /// Comma-separated card IDs to exclude.
    public let excludeCardIds: String?

    // MARK: - State filters

    /// Card condition filter.
    public let condition: CardCondition?
    /// Card workflow states to include.
    public let states: [CardState]?
    /// Filter by archived status.
    public let archived: Bool?
    /// Filter ASAP cards.
    public let asap: Bool?
    /// Filter overdue cards.
    public let overdue: Bool?
    /// Filter cards done on time.
    public let doneOnTime: Bool?
    /// Filter cards that have a due date.
    public let withDueDate: Bool?
    /// Filter service desk request cards.
    public let isRequest: Bool?

    // MARK: - Sorting

    /// Field to order by.
    public let orderBy: String?
    /// Order direction: asc or desc.
    public let orderDirection: String?
    /// Space ID for ordering context.
    public let orderSpaceId: Int?

    // MARK: - Extra

    /// Comma-separated additional fields to include.
    public let additionalCardFields: String?

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
      condition: CardCondition? = nil,
      states: [CardState]? = nil,
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
  public func listCards(
    boardId: Int? = nil, columnId: Int? = nil, laneId: Int? = nil, offset: Int = 0,
    limit: Int = 100, filter: CardFilter? = nil
  ) async throws(KaitenError) -> Page<Components.Schemas.Card> {
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
      condition: f?.condition?.rawValue,
      states: f?.states.map { $0.map { String($0.rawValue) }.joined(separator: ",") },
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
    guard let response = try await callList({ try await client.get_cards(query: queryParams) })
    else {
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

  /// Creates a new card on a board.
  ///
  /// - Parameters:
  ///   - title: Card title (required, max 1024 characters).
  ///   - boardId: Board ID where the card will be created (required).
  ///   - columnId: Column ID. If omitted the board's default column is used.
  ///   - laneId: Lane ID. If omitted the board's default lane is used.
  ///   - description: Card description (max 32768 characters).
  ///   - asap: ASAP marker.
  ///   - dueDate: Deadline in ISO 8601 format.
  ///   - dueDateTimePresent: Whether deadline includes hours and minutes.
  ///   - sortOrder: Position in the cell.
  ///   - expiresLater: Fixed deadline flag.
  ///   - sizeText: Size text (e.g. "1", "S", "XL").
  ///   - ownerId: Owner user ID.
  ///   - responsibleId: Responsible user ID.
  ///   - ownerEmail: Owner email address (only works if email belongs to company user).
  ///   - position: Card position in cell. Overrides sort_order if present.
  ///   - typeId: Card type ID.
  ///   - externalId: External identifier.
  ///   - textFormatTypeId: Text format for card description.
  ///   - properties: Custom properties object.
  /// - Returns: The created card.
  /// - Throws: ``KaitenError``
  public func createCard(
    title: String,
    boardId: Int,
    columnId: Int? = nil,
    laneId: Int? = nil,
    description: String? = nil,
    asap: Bool? = nil,
    dueDate: String? = nil,
    dueDateTimePresent: Bool? = nil,
    sortOrder: Double? = nil,
    expiresLater: Bool? = nil,
    sizeText: String? = nil,
    ownerId: Int? = nil,
    responsibleId: Int? = nil,
    ownerEmail: String? = nil,
    position: CardPosition? = nil,
    typeId: Int? = nil,
    externalId: String? = nil,
    textFormatTypeId: TextFormatType? = nil,
    properties: Components.Schemas.CreateCardRequest.propertiesPayload? = nil
  ) async throws(KaitenError) -> Components.Schemas.Card {
    let body = Components.Schemas.CreateCardRequest(
      title: title,
      board_id: boardId,
      column_id: columnId,
      lane_id: laneId,
      description: description,
      asap: asap,
      due_date: dueDate,
      due_date_time_present: dueDateTimePresent,
      sort_order: sortOrder,
      expires_later: expiresLater,
      size_text: sizeText,
      owner_id: ownerId,
      responsible_id: responsibleId,
      owner_email: ownerEmail,
      position: position?.rawValue,
      type_id: typeId,
      external_id: externalId,
      text_format_type_id: textFormatTypeId?.rawValue,
      properties: properties
    )
    let response = try await call {
      try await client.create_card(body: .json(body))
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates a card by its identifier.
  ///
  /// All fields in the request body are optional — only provided values are changed.
  ///
  /// - Parameters:
  ///   - id: The card identifier.
  ///   - title: New card title.
  ///   - description: New description (pass `nil` wrapped in `.some(nil)` to clear).
  ///   - asap: ASAP marker.
  ///   - dueDate: Deadline in ISO 8601 format (pass `nil` wrapped in `.some(nil)` to clear).
  ///   - dueDateTimePresent: Whether deadline includes hours and minutes.
  ///   - sortOrder: Position in the cell.
  ///   - expiresLater: Fixed deadline flag.
  ///   - sizeText: Size text (e.g. "1", "S", "XL").
  ///   - boardId: Target board ID.
  ///   - columnId: Target column ID.
  ///   - laneId: Target lane ID.
  ///   - ownerId: Owner user ID.
  ///   - typeId: Card type ID.
  ///   - serviceId: Service ID.
  ///   - blocked: Send `false` to release all blocks.
  ///   - condition: Card condition (on board or archived).
  ///   - externalId: External identifier.
  ///   - textFormatTypeId: Text format for card description.
  ///   - sdNewComment: Service Desk new comment flag.
  ///   - ownerEmail: Owner email address.
  ///   - prevCardId: Previous card ID for repositioning.
  ///   - estimateWorkload: Estimated workload.
  ///   - properties: Custom properties object.
  /// - Returns: The updated card.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  public func updateCard(
    id: Int,
    title: String? = nil,
    description: String? = nil,
    asap: Bool? = nil,
    dueDate: String? = nil,
    dueDateTimePresent: Bool? = nil,
    sortOrder: Double? = nil,
    expiresLater: Bool? = nil,
    sizeText: String? = nil,
    boardId: Int? = nil,
    columnId: Int? = nil,
    laneId: Int? = nil,
    ownerId: Int? = nil,
    typeId: Int? = nil,
    serviceId: Int? = nil,
    blocked: Bool? = nil,
    condition: CardCondition? = nil,
    externalId: String? = nil,
    textFormatTypeId: TextFormatType? = nil,
    sdNewComment: Bool? = nil,
    ownerEmail: String? = nil,
    prevCardId: Int? = nil,
    estimateWorkload: Double? = nil,
    properties: Components.Schemas.UpdateCardRequest.propertiesPayload? = nil
  ) async throws(KaitenError) -> Components.Schemas.Card {
    let body = Components.Schemas.UpdateCardRequest(
      title: title,
      description: description,
      asap: asap,
      due_date: dueDate,
      due_date_time_present: dueDateTimePresent,
      sort_order: sortOrder,
      expires_later: expiresLater,
      size_text: sizeText,
      board_id: boardId,
      column_id: columnId,
      lane_id: laneId,
      owner_id: ownerId,
      type_id: typeId,
      service_id: serviceId,
      blocked: blocked,
      condition: condition?.rawValue,
      external_id: externalId,
      text_format_type_id: textFormatTypeId?.rawValue,
      sd_new_comment: sdNewComment,
      owner_email: ownerEmail,
      prev_card_id: prevCardId,
      estimate_workload: estimateWorkload,
      properties: properties
    )
    let response = try await call {
      try await client.update_card(
        path: .init(card_id: id),
        body: .json(body)
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", id)) { try $0.json }
  }

  // MARK: - Card Members

  /// Fetches the list of members assigned to a card.
  ///
  /// - Parameter cardId: The card identifier.
  /// - Returns: An array of detailed member objects. Returns an empty array if no members are assigned.
  /// - Throws: ``KaitenError``
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
  /// - Throws: ``KaitenError``
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
  /// - Throws: ``KaitenError``
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
  /// - Throws: ``KaitenError``
  public func removeCardMember(cardId: Int, userId: Int) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_card_member(path: .init(card_id: cardId, id: userId))
    }
    let result: Components.Schemas.DeletedMemberResponse = try decodeResponse(
      response.toCase(), notFoundResource: ("member", userId)
    ) { try $0.json }
    return result.id
  }

  /// Creates a comment on a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - text: Comment text (markdown).
  /// - Returns: The created comment.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  public func createComment(cardId: Int, text: String) async throws(KaitenError)
    -> Components.Schemas.Comment
  {
    let response = try await call {
      try await client.create_card_comment(
        path: .init(card_id: cardId),
        body: .json(.init(text: text))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }

  /// Updates a comment on a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - commentId: The comment identifier.
  ///   - text: New comment text (markdown).
  /// - Returns: The updated comment.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card or comment does not exist.
  public func updateComment(cardId: Int, commentId: Int, text: String) async throws(KaitenError)
    -> Components.Schemas.Comment
  {
    let response = try await call {
      try await client.update_card_comment(
        path: .init(card_id: cardId, comment_id: commentId),
        body: .json(.init(text: text))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("comment", commentId)) {
      try $0.json
    }
  }

  /// Fetches all comments on a card.
  ///
  /// - Parameter cardId: The card identifier.
  /// - Returns: An array of comments. Returns an empty array if the card has no comments.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  public func getCardComments(cardId: Int) async throws(KaitenError) -> [Components.Schemas.Comment]
  {
    guard
      let response = try await callList({
        try await client.retrieve_card_comments(path: .init(card_id: cardId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }
  // MARK: - Delete Card

  /// Deletes a card.
  ///
  /// - Parameter id: The card identifier.
  /// - Returns: The deleted card.
  public func deleteCard(id: Int) async throws(KaitenError) -> Components.Schemas.Card {
    let response = try await call {
      try await client.delete_card(path: .init(card_id: id))
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", id)) { try $0.json }
  }

  // MARK: - Delete Comment

  /// Deletes a comment from a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - commentId: The comment identifier.
  /// - Returns: The deleted comment ID.
  public func deleteComment(cardId: Int, commentId: Int) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.delete_card_comment(
        path: .init(card_id: cardId, comment_id: commentId))
    }
    let result: Components.Schemas.DeletedCommentResponse = try decodeResponse(
      response.toCase(), notFoundResource: ("comment", commentId)
    ) { try $0.json }
    return result.id
  }

  // MARK: - Checklists

  /// Creates a checklist on a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - name: Checklist name (required).
  ///   - sortOrder: Position (optional).
  /// - Returns: The created checklist.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  public func createChecklist(cardId: Int, name: String, sortOrder: Double? = nil)
    async throws(KaitenError) -> Components.Schemas.Checklist
  {
    let response = try await call {
      try await client.create_checklist(
        path: .init(card_id: cardId),
        body: .json(.init(name: name, sort_order: sortOrder))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }
}

// MARK: - Checklists

extension KaitenClient {
  /// Fetches a single checklist by its identifier.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - checklistId: The checklist identifier.
  /// - Returns: The checklist object.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card or checklist does not exist.
  public func getChecklist(cardId: Int, checklistId: Int) async throws(KaitenError)
    -> Components.Schemas.Checklist
  {
    let response = try await call {
      try await client.get_checklist(path: .init(card_id: cardId, id: checklistId))
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("checklist", checklistId)) {
      try $0.json
    }
  }
}

// MARK: - Remove Checklist

extension KaitenClient {
  /// Removes a checklist from a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - checklistId: The checklist identifier.
  /// - Returns: The deleted checklist ID.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card or checklist does not exist.
  public func removeChecklist(cardId: Int, checklistId: Int) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_checklist(path: .init(card_id: cardId, id: checklistId))
    }
    let result: Components.Schemas.DeletedChecklistResponse = try decodeResponse(
      response.toCase(), notFoundResource: ("checklist", checklistId)
    ) { try $0.json }
    return result.id
  }
}

// MARK: - Checklist Items

extension KaitenClient {
  /// Creates a new checklist item.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - checklistId: The checklist identifier.
  ///   - text: Item content (1–4096 characters).
  ///   - sortOrder: Position (must be > 0).
  ///   - checked: Checked state.
  ///   - dueDate: Due date in YYYY-MM-DD format.
  ///   - responsibleId: Responsible user ID.
  /// - Returns: The created checklist item.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card or checklist does not exist.
  public func createChecklistItem(
    cardId: Int,
    checklistId: Int,
    text: String,
    sortOrder: Double? = nil,
    checked: Bool? = nil,
    dueDate: String? = nil,
    responsibleId: Int? = nil
  ) async throws(KaitenError) -> Components.Schemas.ChecklistItem {
    let response = try await call {
      try await client.create_checklist_item(
        path: .init(card_id: cardId, checklist_id: checklistId),
        body: .json(
          .init(
            text: text,
            sort_order: sortOrder,
            checked: checked,
            due_date: dueDate,
            responsible_id: responsibleId
          ))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("checklist", checklistId)) {
      try $0.json
    }
  }
}

extension KaitenClient {
  /// Updates a checklist item on a card.
  ///
  /// All body parameters are optional — only provided values are changed.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - checklistId: The checklist identifier.
  ///   - itemId: The checklist item identifier.
  ///   - text: Item content (max 4096 characters, pass `nil` to clear).
  ///   - sortOrder: Position (must be > 0).
  ///   - moveToChecklistId: Move item to another checklist.
  ///   - checked: Checked state.
  ///   - dueDate: Due date in YYYY-MM-DD format (pass `nil` to clear).
  ///   - responsibleId: Responsible user ID (pass `nil` to clear).
  /// - Returns: The updated checklist item.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card, checklist, or item does not exist.
  public func updateChecklistItem(
    cardId: Int,
    checklistId: Int,
    itemId: Int,
    text: String? = nil,
    sortOrder: Double? = nil,
    moveToChecklistId: Int? = nil,
    checked: Bool? = nil,
    dueDate: String? = nil,
    responsibleId: Int? = nil
  ) async throws(KaitenError) -> Components.Schemas.ChecklistItem {
    let body = Components.Schemas.UpdateChecklistItemRequest(
      text: text,
      sort_order: sortOrder,
      checklist_id: moveToChecklistId,
      checked: checked,
      due_date: dueDate,
      responsible_id: responsibleId
    )
    let response = try await call {
      try await client.update_checklist_item(
        path: .init(card_id: cardId, checklist_id: checklistId, id: itemId),
        body: .json(body)
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("checklistItem", itemId)) {
      try $0.json
    }
  }
}

// MARK: - Remove Checklist Item

extension KaitenClient {
  /// Removes a checklist item.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - checklistId: The checklist identifier.
  ///   - itemId: The checklist item identifier.
  /// - Returns: The deleted item ID.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card, checklist, or item does not exist.
  public func removeChecklistItem(
    cardId: Int,
    checklistId: Int,
    itemId: Int
  ) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_checklist_item(
        path: .init(card_id: cardId, checklist_id: checklistId, id: itemId)
      )
    }
    let body = try decodeResponse(response.toCase(), notFoundResource: ("checklistItem", itemId)) {
      try $0.json
    }
    return body.id
  }
}

// MARK: - Update Checklist

extension KaitenClient {
  /// Updates a checklist.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - checklistId: The checklist identifier.
  ///   - name: New checklist name (1–1024 characters).
  ///   - sortOrder: New position.
  ///   - moveToCardId: Move checklist to another card.
  /// - Returns: The updated checklist object.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card or checklist does not exist.
  public func updateChecklist(
    cardId: Int,
    checklistId: Int,
    name: String? = nil,
    sortOrder: Double? = nil,
    moveToCardId: Int? = nil
  ) async throws(KaitenError) -> Components.Schemas.Checklist {
    let response = try await call {
      try await client.update_checklist(
        path: .init(card_id: cardId, id: checklistId),
        body: .json(
          .init(
            name: name,
            sort_order: sortOrder,
            card_id: moveToCardId
          ))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("checklist", checklistId)) {
      try $0.json
    }
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
    guard
      let response = try await callList({
        try await client.get_list_of_properties(
          query: .init(
            offset: offset, limit: limit, include_values: includeValues,
            include_author: includeAuthor, compact: compact, load_by_ids: loadByIds, ids: ids,
            order_by: orderBy, order_direction: orderDirection, query: query))
      })
    else {
      return Page(items: [], offset: offset, limit: limit)
    }
    let items: [Components.Schemas.CustomProperty] = try decodeResponse(response.toCase()) {
      try $0.json
    }
    return Page(items: items, offset: offset, limit: limit)
  }

  /// Fetches a single custom property definition by its identifier.
  ///
  /// - Parameter id: The custom property identifier.
  /// - Returns: The custom property definition.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the property does not exist.
  public func getCustomProperty(id: Int) async throws(KaitenError)
    -> Components.Schemas.CustomProperty
  {
    let response = try await call { try await client.get_property(path: .init(id: id)) }
    return try decodeResponse(response.toCase(), notFoundResource: ("customProperty", id)) {
      try $0.json
    }
  }

  /// Lists select values for a select-type custom property.
  ///
  /// - Parameters:
  ///   - propertyId: The custom property identifier.
  ///   - v2SelectSearch: Enable additional filtering capabilities.
  ///   - query: Filter by select value (requires `v2SelectSearch`).
  ///   - orderBy: Field to sort by (requires `v2SelectSearch`).
  ///   - ids: Array of value IDs to filter by (requires `v2SelectSearch`).
  ///   - conditions: Array of conditions to filter by (requires `v2SelectSearch`).
  ///   - offset: Number of records to skip (requires `v2SelectSearch`).
  ///   - limit: Maximum number of values to return (requires `v2SelectSearch`, default `100`).
  /// - Returns: A ``Page`` of select values.
  /// - Throws: ``KaitenError``
  public func listCustomPropertySelectValues(
    propertyId: Int,
    v2SelectSearch: Bool? = nil,
    query: String? = nil,
    orderBy: String? = nil,
    ids: [Int]? = nil,
    conditions: [String]? = nil,
    offset: Int = 0,
    limit: Int = 100
  ) async throws(KaitenError) -> Page<Components.Schemas.CustomPropertySelectValue> {
    guard
      let response = try await callList({
        try await client.get_list_of_select_values(
          path: .init(property_id: propertyId),
          query: .init(
            v2_select_search: v2SelectSearch, query: query, order_by: orderBy,
            ids: ids, conditions: conditions, offset: offset, limit: limit))
      })
    else {
      return Page(items: [], offset: offset, limit: limit)
    }
    let items: [Components.Schemas.CustomPropertySelectValue] = try decodeResponse(
      response.toCase()
    ) { try $0.json }
    return Page(items: items, offset: offset, limit: limit)
  }

  /// Fetches a single select value by its identifier.
  ///
  /// - Parameters:
  ///   - propertyId: The custom property identifier.
  ///   - id: The select value identifier.
  /// - Returns: The select value.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the value does not exist.
  public func getCustomPropertySelectValue(
    propertyId: Int,
    id: Int
  ) async throws(KaitenError) -> Components.Schemas.CustomPropertySelectValue {
    let response = try await call {
      try await client.get_select_value(path: .init(property_id: propertyId, id: id))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("customPropertySelectValue", id)
    ) {
      try $0.json
    }
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
  public func getBoardColumns(boardId: Int) async throws(KaitenError) -> [Components.Schemas.Column]
  {
    guard
      let response = try await callList({
        try await client.get_list_of_columns(path: .init(board_id: boardId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("board", boardId)) {
      try $0.json
    }
  }

  /// Fetches all lanes (horizontal swimlanes) for a board.
  ///
  /// - Parameters:
  ///   - boardId: The board identifier.
  ///   - condition: Optional lane condition filter.
  /// - Returns: An array of lanes. Returns an empty array if the board has no lanes.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the board does not exist.
  public func getBoardLanes(boardId: Int, condition: LaneCondition? = nil) async throws(KaitenError)
    -> [Components.Schemas.Lane]
  {
    guard
      let response = try await callList({
        try await client.get_list_of_lanes(
          path: .init(board_id: boardId), query: .init(condition: condition?.rawValue))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("board", boardId)) {
      try $0.json
    }
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
}

// MARK: - Card Tags

extension KaitenClient {
  /// Lists all tags on a card.
  ///
  /// - Parameter cardId: The card identifier.
  /// - Returns: An array of card tags.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card does not exist.
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
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card does not exist.
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

  // MARK: - Card Children

  /// Lists children of a card.
  ///
  /// - Parameter cardId: The card identifier.
  /// - Returns: An array of card children.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  public func listCardChildren(cardId: Int) async throws(KaitenError) -> [Components.Schemas
    .CardChild]
  {
    guard
      let response = try await callList({
        try await client.list_card_children(path: .init(card_id: cardId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }

  /// Adds a child card to a parent card.
  ///
  /// - Parameters:
  ///   - cardId: The parent card identifier.
  ///   - childCardId: The child card identifier.
  /// - Returns: The created card child.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  public func addCardChild(cardId: Int, childCardId: Int) async throws(KaitenError)
    -> Components.Schemas.CardChild
  {
    let response = try await call {
      try await client.add_card_child(
        path: .init(card_id: cardId),
        body: .json(.init(card_id: childCardId))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }

  /// Removes a child card from a parent card.
  ///
  /// - Parameters:
  ///   - cardId: The parent card identifier.
  ///   - childId: The child card identifier.
  /// - Returns: The deleted child ID.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card or child does not exist.
  public func removeCardChild(cardId: Int, childId: Int) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_card_child(
        path: .init(card_id: cardId, id: childId)
      )
    }
    let body = try decodeResponse(response.toCase(), notFoundResource: ("child", childId)) {
      try $0.json
    }
    return body.id
  }

  /// Removes a tag from a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - tagId: The tag identifier.
  /// - Returns: The deleted tag ID.
  /// - Throws: ``KaitenError/notFound(resource:id:)`` if the card or tag does not exist.
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
  public func getCurrentUser() async throws(KaitenError) -> Components.Schemas.User {
    let response = try await call { try await client.retrieve_current_user() }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}

// MARK: - Card Blockers

extension KaitenClient {
  /// Lists all blockers on a card.
  public func listCardBlockers(cardId: Int) async throws(KaitenError) -> [Components.Schemas
    .CardBlocker]
  {
    guard
      let response = try await callList({
        try await client.list_card_blockers(path: .init(card_id: cardId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }

  /// Creates a blocker on a card.
  public func createCardBlocker(cardId: Int, reason: String? = nil, blockerCardId: Int? = nil)
    async throws(KaitenError) -> Components.Schemas.CardBlocker
  {
    let response = try await call {
      try await client.create_card_blocker(
        path: .init(card_id: cardId),
        body: .json(.init(reason: reason, blocker_card_id: blockerCardId))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }

  /// Updates a card blocker.
  public func updateCardBlocker(
    cardId: Int, blockerId: Int, reason: String? = nil, blockerCardId: Int? = nil
  ) async throws(KaitenError) -> Components.Schemas.CardBlocker {
    let response = try await call {
      try await client.update_card_blocker(
        path: .init(card_id: cardId, id: blockerId),
        body: .json(.init(reason: reason, blocker_card_id: blockerCardId))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("blocker", blockerId)) {
      try $0.json
    }
  }

  /// Deletes a card blocker.
  public func deleteCardBlocker(cardId: Int, blockerId: Int) async throws(KaitenError)
    -> Components.Schemas.CardBlocker
  {
    let response = try await call {
      try await client.delete_card_blocker(
        path: .init(card_id: cardId, id: blockerId)
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("blocker", blockerId)) {
      try $0.json
    }
  }
}

// MARK: - Card Types

extension KaitenClient {
  /// Lists card types.
  public func listCardTypes(
    limit: Int? = nil, offset: Int? = nil
  ) async throws(KaitenError) -> [Components.Schemas.CardType] {
    guard
      let response = try await callList({
        try await client.list_card_types(query: .init(limit: limit, offset: offset))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}

// MARK: - Sprints

extension KaitenClient {
  /// Lists sprints.
  public func listSprints(
    active: Bool? = nil, limit: Int? = nil, offset: Int? = nil
  ) async throws(KaitenError) -> [Components.Schemas.Sprint] {
    guard
      let response = try await callList({
        try await client.list_sprints(query: .init(active: active, limit: limit, offset: offset))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}

// MARK: - Card Location History

extension KaitenClient {
  /// Gets card location history.
  public func getCardLocationHistory(
    cardId: Int
  ) async throws(KaitenError) -> [Components.Schemas.CardLocationHistory] {
    guard
      let response = try await callList({
        try await client.get_card_location_history(path: .init(card_id: cardId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }
}

// MARK: - External Links

extension KaitenClient {
  /// Lists all external links on a card.
  public func listExternalLinks(cardId: Int) async throws(KaitenError) -> [Components.Schemas
    .ExternalLink]
  {
    guard
      let response = try await callList({
        try await client.list_card_external_links(path: .init(card_id: cardId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }

  /// Creates an external link on a card.
  public func createExternalLink(cardId: Int, url: String, description: String? = nil)
    async throws(KaitenError) -> Components.Schemas.ExternalLink
  {
    let response = try await call {
      try await client.create_card_external_link(
        path: .init(card_id: cardId),
        body: .json(.init(url: url, description: description))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }

  /// Updates an external link on a card.
  public func updateExternalLink(
    cardId: Int, linkId: Int, url: String? = nil, description: String? = nil
  )
    async throws(KaitenError) -> Components.Schemas.ExternalLink
  {
    let response = try await call {
      try await client.update_card_external_link(
        path: .init(card_id: cardId, id: linkId),
        body: .json(.init(url: url, description: description))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("externalLink", linkId)) {
      try $0.json
    }
  }

  /// Removes an external link from a card.
  public func removeExternalLink(cardId: Int, linkId: Int) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_card_external_link(path: .init(card_id: cardId, id: linkId))
    }
    let result: Components.Schemas.DeletedExternalLinkResponse = try decodeResponse(
      response.toCase(), notFoundResource: ("externalLink", linkId)
    ) { try $0.json }
    return result.id
  }
}

// MARK: - Helpers

extension Optional {
  func orThrow(_ error: @autoclosure () -> KaitenError) throws(KaitenError) -> Wrapped {
    guard let self else { throw error() }
    return self
  }
}

// MARK: - Sprint Summary

extension KaitenClient {
  /// Gets a sprint summary by ID.
  public func getSprintSummary(
    id: Int, excludeDeletedCards: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.SprintSummary {
    let response = try await call {
      try await client.get_sprint_summary(
        path: .init(id: id),
        query: .init(exclude_deleted_cards: excludeDeletedCards)
      )
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("sprint", id)
    ) { try $0.json }
  }
}

// MARK: - Spaces CRUD

extension KaitenClient {
  /// Creates a new space.
  public func createSpace(
    title: String,
    externalId: String? = nil,
    parentEntityUid: String? = nil,
    sortOrder: Double? = nil
  ) async throws(KaitenError) -> Components.Schemas.Space {
    let response = try await call {
      try await client.create_space(
        body: .json(
          .init(
            title: title,
            external_id: externalId,
            parent_entity_uid: parentEntityUid,
            sort_order: sortOrder
          )))
    }
    return try decodeResponse(response.toCase()) {
      try $0.json
    }
  }

  /// Gets a space by ID.
  public func getSpace(
    id: Int
  ) async throws(KaitenError) -> Components.Schemas.Space {
    let response = try await call {
      try await client.retrieve_space(path: .init(space_id: id))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("space", id)
    ) { try $0.json }
  }

  /// Updates a space.
  public func updateSpace(
    id: Int,
    title: String? = nil,
    externalId: String? = nil,
    sortOrder: Double? = nil,
    access: String? = nil,
    parentEntityUid: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.Space {
    let response = try await call {
      try await client.update_space(
        path: .init(space_id: id),
        body: .json(
          .init(
            title: title,
            external_id: externalId,
            sort_order: sortOrder,
            access: access,
            parent_entity_uid: parentEntityUid
          )))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("space", id)
    ) { try $0.json }
  }

}

// MARK: - Boards CRUD

extension KaitenClient {
  /// Creates a new board in a space.
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

// MARK: - Columns CRUD

extension KaitenClient {
  /// Creates a new column on a board.
  public func createColumn(
    boardId: Int,
    title: String,
    sortOrder: Double? = nil,
    type: ColumnType? = nil,
    wipLimit: Int? = nil,
    wipLimitType: WipLimitType? = nil,
    colCount: Int? = nil
  ) async throws(KaitenError) -> Components.Schemas.Column {
    let response = try await call {
      try await client.create_column(
        path: .init(board_id: boardId),
        body: .json(
          .init(
            title: title,
            sort_order: sortOrder,
            _type: type?.rawValue,
            wip_limit: wipLimit,
            wip_limit_type: wipLimitType?.rawValue,
            col_count: colCount
          )))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("board", boardId)
    ) { try $0.json }
  }

  /// Updates a column.
  public func updateColumn(
    boardId: Int,
    id: Int,
    title: String? = nil,
    sortOrder: Double? = nil,
    type: ColumnType? = nil,
    wipLimit: Int? = nil,
    wipLimitType: WipLimitType? = nil,
    colCount: Int? = nil
  ) async throws(KaitenError) -> Components.Schemas.Column {
    let response = try await call {
      try await client.update_column(
        path: .init(board_id: boardId, id: id),
        body: .json(
          .init(
            title: title,
            sort_order: sortOrder,
            _type: type?.rawValue,
            wip_limit: wipLimit,
            wip_limit_type: wipLimitType?.rawValue,
            col_count: colCount
          )))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("column", id)
    ) { try $0.json }
  }

  /// Deletes a column.
  public func deleteColumn(
    boardId: Int, id: Int
  ) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_column(
        path: .init(board_id: boardId, id: id)
      )
    }
    let result: Components.Schemas.DeletedIdResponse =
      try decodeResponse(
        response.toCase(), notFoundResource: ("column", id)
      ) { try $0.json }
    return result.id
  }
}

// MARK: - Subcolumns

extension KaitenClient {
  /// Lists subcolumns of a column.
  public func listSubcolumns(
    columnId: Int
  ) async throws(KaitenError) -> [Components.Schemas.Column] {
    guard
      let response = try await callList({
        try await client.get_list_of_subcolumns(
          path: .init(column_id: columnId)
        )
      })
    else {
      return []
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("column", columnId)
    ) { try $0.json }
  }

  /// Creates a subcolumn.
  public func createSubcolumn(
    columnId: Int,
    title: String,
    sortOrder: Double? = nil,
    type: ColumnType? = nil
  ) async throws(KaitenError) -> Components.Schemas.Column {
    let response = try await call {
      try await client.create_subcolumn(
        path: .init(column_id: columnId),
        body: .json(
          .init(
            title: title,
            sort_order: sortOrder,
            _type: type?.rawValue
          )))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("column", columnId)
    ) { try $0.json }
  }

  /// Updates a subcolumn.
  public func updateSubcolumn(
    columnId: Int,
    id: Int,
    title: String? = nil,
    sortOrder: Double? = nil,
    type: ColumnType? = nil
  ) async throws(KaitenError) -> Components.Schemas.Column {
    let response = try await call {
      try await client.update_subcolumn(
        path: .init(column_id: columnId, id: id),
        body: .json(
          .init(
            title: title,
            sort_order: sortOrder,
            _type: type?.rawValue
          )))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("subcolumn", id)
    ) { try $0.json }
  }

  /// Deletes a subcolumn.
  public func deleteSubcolumn(
    columnId: Int, id: Int
  ) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_subcolumn(
        path: .init(column_id: columnId, id: id)
      )
    }
    let result: Components.Schemas.DeletedIdResponse =
      try decodeResponse(
        response.toCase(), notFoundResource: ("subcolumn", id)
      ) { try $0.json }
    return result.id
  }
}

// MARK: - Lanes CRUD

extension KaitenClient {
  /// Creates a new lane on a board.
  public func createLane(
    boardId: Int,
    title: String,
    sortOrder: Double? = nil,
    wipLimit: Int? = nil,
    wipLimitType: WipLimitType? = nil,
    rowCount: Int? = nil
  ) async throws(KaitenError) -> Components.Schemas.Lane {
    let response = try await call {
      try await client.create_lane(
        path: .init(board_id: boardId),
        body: .json(
          .init(
            title: title,
            sort_order: sortOrder,
            wip_limit: wipLimit,
            wip_limit_type: wipLimitType?.rawValue,
            row_count: rowCount
          )))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("board", boardId)
    ) { try $0.json }
  }

  /// Updates a lane.
  public func updateLane(
    boardId: Int,
    id: Int,
    title: String? = nil,
    sortOrder: Double? = nil,
    wipLimit: Int? = nil,
    wipLimitType: WipLimitType? = nil,
    rowCount: Int? = nil,
    condition: LaneCondition? = nil
  ) async throws(KaitenError) -> Components.Schemas.Lane {
    let response = try await call {
      try await client.update_lane(
        path: .init(board_id: boardId, id: id),
        body: .json(
          .init(
            title: title,
            sort_order: sortOrder,
            wip_limit: wipLimit,
            wip_limit_type: wipLimitType?.rawValue,
            row_count: rowCount,
            condition: condition?.rawValue
          )))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("lane", id)
    ) { try $0.json }
  }

}

// MARK: - Card Baselines

extension KaitenClient {
  /// Gets card baselines.
  public func getCardBaselines(
    cardId: Int
  ) async throws(KaitenError)
    -> [Components.Schemas.CardBaseline]
  {
    guard
      let response = try await callList({
        try await client.get_card_baselines(
          path: .init(card_id: cardId)
        )
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}
