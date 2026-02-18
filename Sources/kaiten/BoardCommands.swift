import ArgumentParser
import KaitenSDK

// MARK: - Boards

struct ListBoards: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-boards",
    abstract: "List boards in a space"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space ID")
  var spaceId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let boards = try await client.listBoards(spaceId: spaceId)
    try printJSON(boards)
  }
}

struct GetBoard: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-board",
    abstract: "Get a board by ID"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let board = try await client.getBoard(id: id)
    try printJSON(board)
  }
}

struct GetBoardColumns: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-board-columns",
    abstract: "Get columns of a board"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID")
  var boardId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let columns = try await client.getBoardColumns(boardId: boardId)
    try printJSON(columns)
  }
}

struct GetBoardLanes: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-board-lanes",
    abstract: "Get lanes of a board"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID")
  var boardId: Int

  @Option(name: .long, help: "Lane condition: 1 = live, 2 = archived, 3 = deleted")
  var condition: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let lanes = try await client.getBoardLanes(
      boardId: boardId, condition: condition.flatMap(LaneCondition.init(rawValue:)))
    try printJSON(lanes)
  }
}
