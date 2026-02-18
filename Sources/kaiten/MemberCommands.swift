import ArgumentParser
import KaitenSDK

struct AddCardMember: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add-card-member",
    abstract: "Add a member to a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "User ID")
  var userId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let member = try await client.addCardMember(cardId: cardId, userId: userId)
    try printJSON(member)
  }
}

struct UpdateCardMemberRole: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-card-member-role",
    abstract: "Update a card member's role"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "User ID")
  var userId: Int

  @Option(name: .long, help: "Role type (2 = responsible)")
  var type: Int

  func run() async throws {
    let client = try await global.makeClient()
    let role = try await client.updateCardMemberRole(cardId: cardId, userId: userId, type: type)
    try printJSON(role)
  }
}

struct RemoveCardMember: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-card-member",
    abstract: "Remove a member from a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "User ID")
  var userId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.removeCardMember(cardId: cardId, userId: userId)
    try printJSON(["id": deletedId])
  }
}
