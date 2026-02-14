import Configuration
import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

/// Main entry point for the Kaiten SDK.
///
/// Reads `KAITEN_URL` and `KAITEN_TOKEN` from environment variables.
/// Fails fast if either is missing.
public struct KaitenClient: Sendable {
    private let client: Client
    private let config: KaitenConfiguration

    /// Creates a new ``KaitenClient``.
    ///
    /// - Throws: ``KaitenError/missingConfiguration(_:)`` if `KAITEN_URL` or `KAITEN_TOKEN`
    ///   are not found in the environment.
    public init() throws {
        self.config = try KaitenConfiguration.resolve()

        let url = try URL(string: config.baseURL)
            .orThrow(KaitenError.invalidURL(config.baseURL))

        self.client = Client(
            serverURL: url,
            transport: URLSessionTransport()
        )
    }
}

// MARK: - Configuration

struct KaitenConfiguration: Sendable {
    let baseURL: String
    let token: String

    static func resolve() throws -> KaitenConfiguration {
        let config = ConfigReader(providers: [
            EnvironmentVariablesProvider(),
        ])

        guard let url: String = config.string(forKey: "KAITEN_URL") else {
            throw KaitenError.missingConfiguration("KAITEN_URL")
        }
        guard let token: String = config.string(forKey: "KAITEN_TOKEN") else {
            throw KaitenError.missingConfiguration("KAITEN_TOKEN")
        }

        return KaitenConfiguration(baseURL: url, token: token)
    }
}

// MARK: - Errors

// MARK: - Helpers

extension Optional {
    func orThrow(_ error: @autoclosure () -> some Error) throws -> Wrapped {
        guard let self else { throw error() }
        return self
    }
}
