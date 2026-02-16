import ArgumentParser
import Configuration
import Foundation
import KaitenSDK
import SystemPackage

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

// MARK: - Global Options

struct GlobalOptions: ParsableArguments {
    @Option(name: .long, help: "Kaiten API base URL (overrides config file)")
    var url: String?

    @Option(name: .long, help: "Kaiten API token (overrides config file)")
    var token: String?

    func makeClient() async throws -> KaitenClient {
        let configPath = Self.configPath

        let providers: [ConfigProvider] = [
            (try? await FileProvider<JSONSnapshot>(filePath: FilePath(configPath))) as ConfigProvider?,
        ].compactMap { $0 }

        // If no config file exists, don't create ConfigReader — rely on CLI flags (#81)
        let config: ConfigReader? = providers.isEmpty ? nil : ConfigReader(providers: providers)

        guard let baseURL = url ?? config?.string(forKey: "url") else {
            throw ValidationError(
                "Missing Kaiten API URL. Pass --url or set \"url\" in \(configPath)"
            )
        }
        guard let apiToken = token ?? config?.string(forKey: "token") else {
            throw ValidationError(
                "Missing Kaiten API token. Pass --token or set \"token\" in \(configPath)"
            )
        }
        return try KaitenClient(baseURL: baseURL, token: apiToken)
    }

    private static var configPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/kaiten-mcp/config.json").path
    }
}

// MARK: - Helpers

func printJSON(_ value: some Encodable) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(value)
    print(String(data: data, encoding: .utf8)!)
}
