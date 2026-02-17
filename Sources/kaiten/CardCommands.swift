import ArgumentParser
import KaitenSDK

// MARK: - Cards

struct ListCards: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-cards",
        abstract: "List cards on a board (paginated)"
    )

    @OptionGroup var global: GlobalOptions

    @Option(name: .long, help: "Board ID")
    var boardId: Int?

    @Option(name: .long, help: "Column ID")
    var columnId: Int?

    @Option(name: .long, help: "Lane ID")
    var laneId: Int?

    @Option(name: .long, help: "Offset for pagination (default: 0)")
    var offset: Int = 0

    @Option(name: .long, help: "Limit for pagination (default/max: 100)")
    var limit: Int = 100

    // Date filters
    @Option(name: .long, help: "Filter cards created before this date (ISO 8601)")
    var createdBefore: String?

    @Option(name: .long, help: "Filter cards created after this date (ISO 8601)")
    var createdAfter: String?

    @Option(name: .long, help: "Filter cards updated before this date (ISO 8601)")
    var updatedBefore: String?

    @Option(name: .long, help: "Filter cards updated after this date (ISO 8601)")
    var updatedAfter: String?

    @Option(name: .long, help: "Filter cards first moved to in-progress after this date")
    var firstMovedInProgressAfter: String?

    @Option(name: .long, help: "Filter cards first moved to in-progress before this date")
    var firstMovedInProgressBefore: String?

    @Option(name: .long, help: "Filter cards last moved to done after this date")
    var lastMovedToDoneAtAfter: String?

    @Option(name: .long, help: "Filter cards last moved to done before this date")
    var lastMovedToDoneAtBefore: String?

    @Option(name: .long, help: "Filter cards with due date after this date")
    var dueDateAfter: String?

    @Option(name: .long, help: "Filter cards with due date before this date")
    var dueDateBefore: String?

    // Text search
    @Option(name: .long, help: "Text search query")
    var query: String?

    @Option(name: .long, help: "Comma-separated fields to search in")
    var searchFields: String?

    // Tags
    @Option(name: .long, help: "Filter by tag name")
    var tag: String?

    @Option(name: .long, help: "Comma-separated tag IDs")
    var tagIds: String?

    // ID filters
    @Option(name: .long, help: "Filter by card type ID")
    var typeId: Int?

    @Option(name: .long, help: "Comma-separated card type IDs")
    var typeIds: String?

    @Option(name: .long, help: "Comma-separated member user IDs")
    var memberIds: String?

    @Option(name: .long, help: "Filter by owner user ID")
    var ownerId: Int?

    @Option(name: .long, help: "Comma-separated owner user IDs")
    var ownerIds: String?

    @Option(name: .long, help: "Filter by responsible user ID")
    var responsibleId: Int?

    @Option(name: .long, help: "Comma-separated responsible user IDs")
    var responsibleIds: String?

    @Option(name: .long, help: "Comma-separated column IDs")
    var columnIds: String?

    @Option(name: .long, help: "Filter by space ID")
    var spaceId: Int?

    @Option(name: .long, help: "Filter by external ID")
    var externalId: String?

    @Option(name: .long, help: "Comma-separated organization IDs")
    var organizationsIds: String?

    // Exclude filters
    @Option(name: .long, help: "Comma-separated board IDs to exclude")
    var excludeBoardIds: String?

    @Option(name: .long, help: "Comma-separated lane IDs to exclude")
    var excludeLaneIds: String?

    @Option(name: .long, help: "Comma-separated column IDs to exclude")
    var excludeColumnIds: String?

    @Option(name: .long, help: "Comma-separated owner IDs to exclude")
    var excludeOwnerIds: String?

    @Option(name: .long, help: "Comma-separated card IDs to exclude")
    var excludeCardIds: String?

    // State filters
    @Option(name: .long, help: "Card condition: 1 = on board, 2 = archived")
    var condition: Int?

    @Option(name: .long, help: "Comma-separated states: 1 = queued, 2 = in progress, 3 = done")
    var states: String?

    @Option(name: .long, help: "Filter by archived status")
    var archived: Bool?

    @Option(name: .long, help: "Filter ASAP cards")
    var asap: Bool?

    @Option(name: .long, help: "Filter overdue cards")
    var overdue: Bool?

    @Option(name: .long, help: "Filter cards done on time")
    var doneOnTime: Bool?

    @Option(name: .long, help: "Filter cards that have a due date")
    var withDueDate: Bool?

    @Option(name: .long, help: "Filter service desk request cards")
    var isRequest: Bool?

    // Sorting
    @Option(name: .long, help: "Field to order by")
    var orderBy: String?

    @Option(name: .long, help: "Order direction: asc or desc")
    var orderDirection: String?

    @Option(name: .long, help: "Space ID for ordering context")
    var orderSpaceId: Int?

    // Extra
    @Option(name: .long, help: "Comma-separated additional fields to include")
    var additionalCardFields: String?

    func run() async throws {
        let client = try await global.makeClient()
        let filter = KaitenClient.CardFilter(
            createdBefore: try DateParsing.parse(createdBefore),
            createdAfter: try DateParsing.parse(createdAfter),
            updatedBefore: try DateParsing.parse(updatedBefore),
            updatedAfter: try DateParsing.parse(updatedAfter),
            firstMovedInProgressAfter: try DateParsing.parse(firstMovedInProgressAfter),
            firstMovedInProgressBefore: try DateParsing.parse(firstMovedInProgressBefore),
            lastMovedToDoneAtAfter: try DateParsing.parse(lastMovedToDoneAtAfter),
            lastMovedToDoneAtBefore: try DateParsing.parse(lastMovedToDoneAtBefore),
            dueDateAfter: try DateParsing.parse(dueDateAfter),
            dueDateBefore: try DateParsing.parse(dueDateBefore),
            query: query,
            searchFields: searchFields,
            tag: tag,
            tagIds: tagIds,
            typeId: typeId,
            typeIds: typeIds,
            memberIds: memberIds,
            ownerId: ownerId,
            ownerIds: ownerIds,
            responsibleId: responsibleId,
            responsibleIds: responsibleIds,
            columnIds: columnIds,
            spaceId: spaceId,
            externalId: externalId,
            organizationsIds: organizationsIds,
            excludeBoardIds: excludeBoardIds,
            excludeLaneIds: excludeLaneIds,
            excludeColumnIds: excludeColumnIds,
            excludeOwnerIds: excludeOwnerIds,
            excludeCardIds: excludeCardIds,
            condition: condition,
            states: states,
            archived: archived,
            asap: asap,
            overdue: overdue,
            doneOnTime: doneOnTime,
            withDueDate: withDueDate,
            isRequest: isRequest,
            orderBy: orderBy,
            orderDirection: orderDirection,
            orderSpaceId: orderSpaceId,
            additionalCardFields: additionalCardFields
        )
        let page = try await client.listCards(boardId: boardId, columnId: columnId, laneId: laneId, offset: offset, limit: limit, filter: filter)
        try printJSON(page)
    }
}

struct GetCard: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get-card",
        abstract: "Get a card by ID"
    )

    @OptionGroup var global: GlobalOptions

    @Option(name: .long, help: "Card ID")
    var id: Int

    func run() async throws {
        let client = try await global.makeClient()
        let card = try await client.getCard(id: id)
        try printJSON(card)
    }
}

struct GetCardComments: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get-card-comments",
        abstract: "Get comments on a card"
    )

    @OptionGroup var global: GlobalOptions

    @Option(name: .long, help: "Card ID")
    var cardId: Int

    func run() async throws {
        let client = try await global.makeClient()
        let comments = try await client.getCardComments(cardId: cardId)
        try printJSON(comments)
    }
}

struct GetCardMembers: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get-card-members",
        abstract: "Get members of a card"
    )

    @OptionGroup var global: GlobalOptions

    @Option(name: .long, help: "Card ID")
    var cardId: Int

    func run() async throws {
        let client = try await global.makeClient()
        let members = try await client.getCardMembers(cardId: cardId)
        try printJSON(members)
    }
}
