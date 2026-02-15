import ArgumentParser
import Foundation
import KaitenSDK

@main
struct Kaiten: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "kaiten",
        abstract: "CLI for Kaiten API",
        subcommands: [
            ListSpaces.self,
            ListBoards.self,
            GetBoard.self,
            GetBoardColumns.self,
            GetBoardLanes.self,
            ListCards.self,
            GetCard.self,
            GetCardMembers.self,
            ListCustomProperties.self,
            GetCustomProperty.self,
        ]
    )
}

// MARK: - Helpers

func printJSON(_ value: some Encodable) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(value)
    print(String(data: data, encoding: .utf8)!)
}

// MARK: - Spaces & Boards

struct ListSpaces: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-spaces",
        abstract: "List all spaces"
    )

    func run() async throws {
        let client = try KaitenClient()
        let spaces = try await client.listSpaces()
        try printJSON(spaces)
    }
}

struct ListBoards: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-boards",
        abstract: "List boards in a space"
    )

    @Option(name: .long, help: "Space ID")
    var spaceId: Int

    func run() async throws {
        let client = try KaitenClient()
        let boards = try await client.listBoards(spaceId: spaceId)
        try printJSON(boards)
    }
}

struct GetBoard: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get-board",
        abstract: "Get a board by ID"
    )

    @Option(name: .long, help: "Board ID")
    var id: Int

    func run() async throws {
        let client = try KaitenClient()
        let board = try await client.getBoard(id: id)
        try printJSON(board)
    }
}

struct GetBoardColumns: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get-board-columns",
        abstract: "Get columns of a board"
    )

    @Option(name: .long, help: "Board ID")
    var boardId: Int

    func run() async throws {
        let client = try KaitenClient()
        let columns = try await client.getBoardColumns(boardId: boardId)
        try printJSON(columns)
    }
}

struct GetBoardLanes: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get-board-lanes",
        abstract: "Get lanes of a board"
    )

    @Option(name: .long, help: "Board ID")
    var boardId: Int

    func run() async throws {
        let client = try KaitenClient()
        let lanes = try await client.getBoardLanes(boardId: boardId)
        try printJSON(lanes)
    }
}

// MARK: - Cards

struct ListCards: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-cards",
        abstract: "List all cards on a board"
    )

    @Option(name: .long, help: "Board ID")
    var boardId: Int

    func run() async throws {
        let client = try KaitenClient()
        let cards = try await client.listCards(boardId: boardId)
        try printJSON(cards)
    }
}

struct GetCard: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get-card",
        abstract: "Get a card by ID"
    )

    @Option(name: .long, help: "Card ID")
    var id: Int

    func run() async throws {
        let client = try KaitenClient()
        let card = try await client.getCard(id: id)
        try printJSON(card)
    }
}

struct GetCardMembers: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get-card-members",
        abstract: "Get members of a card"
    )

    @Option(name: .long, help: "Card ID")
    var cardId: Int

    func run() async throws {
        let client = try KaitenClient()
        let members = try await client.getCardMembers(cardId: cardId)
        try printJSON(members)
    }
}

// MARK: - Custom Properties

struct ListCustomProperties: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-custom-properties",
        abstract: "List all custom property definitions"
    )

    func run() async throws {
        let client = try KaitenClient()
        let props = try await client.listCustomProperties()
        try printJSON(props)
    }
}

struct GetCustomProperty: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get-custom-property",
        abstract: "Get a custom property by ID"
    )

    @Option(name: .long, help: "Custom property ID")
    var id: Int

    func run() async throws {
        let client = try KaitenClient()
        let prop = try await client.getCustomProperty(id: id)
        try printJSON(prop)
    }
}
