import ArgumentParser
import KaitenSDK

struct CreateColumn: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-column",
    abstract: "Create a new column on a board"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID")
  var boardId: Int

  @Option(name: .long, help: "Column title")
  var title: String

  @Option(name: .long, help: "Sort order")
  var sortOrder: Double?

  @Option(name: .long, help: "Column type: 1=queue, 2=in progress, 3=done")
  var columnType: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let column = try await client.createColumn(
      boardId: boardId,
      title: title,
      sortOrder: sortOrder,
      type: columnType.flatMap(ColumnType.init(rawValue:))
    )
    try printJSON(column)
  }
}

struct UpdateColumn: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-column",
    abstract: "Update a column"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID")
  var boardId: Int

  @Option(name: .long, help: "Column ID")
  var id: Int

  @Option(name: .long, help: "Column title")
  var title: String?

  @Option(name: .long, help: "Sort order")
  var sortOrder: Double?

  @Option(name: .long, help: "Column type: 1=queue, 2=in progress, 3=done")
  var columnType: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let column = try await client.updateColumn(
      boardId: boardId,
      id: id,
      title: title,
      sortOrder: sortOrder,
      type: columnType.flatMap(ColumnType.init(rawValue:))
    )
    try printJSON(column)
  }
}

struct DeleteColumn: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-column",
    abstract: "Delete a column"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID")
  var boardId: Int

  @Option(name: .long, help: "Column ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.deleteColumn(
      boardId: boardId,
      id: id
    )
    print("{\"id\": \(deletedId)}")
  }
}

// MARK: - Subcolumns

struct ListSubcolumns: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-subcolumns",
    abstract: "List subcolumns of a column"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Column ID")
  var columnId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let subcolumns = try await client.listSubcolumns(
      columnId: columnId
    )
    try printJSON(subcolumns)
  }
}

struct CreateSubcolumn: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-subcolumn",
    abstract: "Create a new subcolumn"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Column ID")
  var columnId: Int

  @Option(name: .long, help: "Subcolumn title")
  var title: String

  @Option(name: .long, help: "Sort order")
  var sortOrder: Double?

  func run() async throws {
    let client = try await global.makeClient()
    let subcolumn = try await client.createSubcolumn(
      columnId: columnId,
      title: title,
      sortOrder: sortOrder
    )
    try printJSON(subcolumn)
  }
}

struct UpdateSubcolumn: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-subcolumn",
    abstract: "Update a subcolumn"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Column ID")
  var columnId: Int

  @Option(name: .long, help: "Subcolumn ID")
  var id: Int

  @Option(name: .long, help: "Subcolumn title")
  var title: String?

  @Option(name: .long, help: "Sort order")
  var sortOrder: Double?

  func run() async throws {
    let client = try await global.makeClient()
    let subcolumn = try await client.updateSubcolumn(
      columnId: columnId,
      id: id,
      title: title,
      sortOrder: sortOrder
    )
    try printJSON(subcolumn)
  }
}

struct DeleteSubcolumn: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-subcolumn",
    abstract: "Delete a subcolumn"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Column ID")
  var columnId: Int

  @Option(name: .long, help: "Subcolumn ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.deleteSubcolumn(
      columnId: columnId,
      id: id
    )
    print("{\"id\": \(deletedId)}")
  }
}
