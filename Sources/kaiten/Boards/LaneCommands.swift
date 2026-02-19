import ArgumentParser
import KaitenSDK

struct CreateLane: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-lane",
    abstract: "Create a new lane on a board"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID")
  var boardId: Int

  @Option(name: .long, help: "Lane title")
  var title: String

  @Option(name: .long, help: "Sort order")
  var sortOrder: Double?

  @Option(name: .long, help: "Row count (height)")
  var rowCount: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let lane = try await client.createLane(
      boardId: boardId,
      title: title,
      sortOrder: sortOrder,
      rowCount: rowCount
    )
    try printJSON(lane)
  }
}

struct UpdateLane: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-lane",
    abstract: "Update a lane"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID")
  var boardId: Int

  @Option(name: .long, help: "Lane ID")
  var id: Int

  @Option(name: .long, help: "Lane title")
  var title: String?

  @Option(name: .long, help: "Sort order")
  var sortOrder: Double?

  @Option(name: .long, help: "Row count (height)")
  var rowCount: Int?

  @Option(name: .long, help: "Condition: 1=live, 2=archived")
  var condition: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let lane = try await client.updateLane(
      boardId: boardId,
      id: id,
      title: title,
      sortOrder: sortOrder,
      condition: condition.flatMap(LaneCondition.init(rawValue:))
    )
    try printJSON(lane)
  }
}
