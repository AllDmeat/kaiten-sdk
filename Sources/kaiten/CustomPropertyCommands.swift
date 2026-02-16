import ArgumentParser
import KaitenSDK

// MARK: - Custom Properties

struct ListCustomProperties: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-custom-properties",
        abstract: "List all custom property definitions"
    )

    @OptionGroup var global: GlobalOptions

    func run() async throws {
        let client = try await global.makeClient()
        let props = try await client.listCustomProperties()
        try printJSON(props)
    }
}

struct GetCustomProperty: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get-custom-property",
        abstract: "Get a custom property by ID"
    )

    @OptionGroup var global: GlobalOptions

    @Option(name: .long, help: "Custom property ID")
    var id: Int

    func run() async throws {
        let client = try await global.makeClient()
        let prop = try await client.getCustomProperty(id: id)
        try printJSON(prop)
    }
}
