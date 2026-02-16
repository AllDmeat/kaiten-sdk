import ArgumentParser
import KaitenSDK

// MARK: - Cards

struct ListCards: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-cards",
        abstract: "List all cards on a board"
    )

    @OptionGroup var global: GlobalOptions

    @Option(name: .long, help: "Board ID")
    var boardId: Int

    func run() async throws {
        let client = try await global.makeClient()
        let cards = try await client.listCards(boardId: boardId)
        try printJSON(cards)
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
