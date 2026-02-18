import ArgumentParser
import KaitenSDK

struct CreateChecklist: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-checklist",
    abstract: "Create a checklist on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Checklist name")
  var name: String

  @Option(name: .long, help: "Position (sort order)")
  var sortOrder: Double?

  func run() async throws {
    let client = try await global.makeClient()
    let checklist = try await client.createChecklist(
      cardId: cardId, name: name, sortOrder: sortOrder)
    try printJSON(checklist)
  }
}

// MARK: - Checklists

struct GetChecklist: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-checklist",
    abstract: "Retrieve a card checklist"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Checklist ID")
  var checklistId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let checklist = try await client.getChecklist(cardId: cardId, checklistId: checklistId)
    try printJSON(checklist)
  }
}
