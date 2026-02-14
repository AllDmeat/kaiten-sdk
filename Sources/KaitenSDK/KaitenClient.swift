import Configuration
import OpenAPIRuntime
import OpenAPIURLSession

/// Main entry point for the Kaiten SDK.
///
/// Reads `KAITEN_URL` and `KAITEN_TOKEN` from the configuration (environment variables).
/// Fails fast if either is missing.
public struct KaitenClient: Sendable {
    private let client: Client
    private let config: KaitenConfiguration

    /// Creates a new ``KaitenClient``.
    ///
    /// - Throws: ``KaitenError/missingConfiguration(_:)`` if `KAITEN_URL` or `KAITEN_TOKEN`
    ///   are not found in the configuration.
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
        let configuration = ConfigurationManager()
        configuration.load(.environmentVariables)

        guard let url: String = configuration.retrieve("KAITEN_URL") else {
            throw KaitenError.missingConfiguration("KAITEN_URL")
        }
        guard let token: String = configuration.retrieve("KAITEN_TOKEN") else {
            throw KaitenError.missingConfiguration("KAITEN_TOKEN")
        }

        return KaitenConfiguration(baseURL: url, token: token)
    }
}

// MARK: - Errors

/// Errors thrown by the Kaiten SDK.
public enum KaitenError: Error, Sendable {
    /// A required configuration value is missing.
    case missingConfiguration(String)
    /// The provided URL is invalid.
    case invalidURL(String)
}

// MARK: - Helpers

extension Optional {
    func orThrow(_ error: @autoclosure () -> some Error) throws -> Wrapped {
        guard let self else { throw error() }
        return self
    }
}
