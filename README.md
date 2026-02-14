# KaitenSDK

[![Build](https://github.com/AllDmeat/KaitenSDK/actions/workflows/ci.yml/badge.svg)](https://github.com/AllDmeat/KaitenSDK/actions/workflows/ci.yml)

Swift SDK for the [Kaiten](https://kaiten.ru) project management API. OpenAPI-generated types with typed errors, automatic retry on `429 Too Many Requests`, and Bearer token authentication.

## Requirements

- Swift 6.2+
- macOS 15+ / Linux

## Installation

Add KaitenSDK to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/AllDmeat/KaitenSDK.git", from: "0.1.0"),
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "KaitenSDK", package: "KaitenSDK"),
        ]
    ),
]
```

## Quick Start

Set the required environment variables:

```bash
export KAITEN_URL="https://your-company.kaiten.ru/api/latest"
export KAITEN_TOKEN="your-api-token"
```

Then use the client:

```swift
import KaitenSDK

let client = try KaitenClient()

let spaces = try await client.listSpaces()
let cards = try await client.listCards(boardId: 42)
let card = try await client.getCard(id: 123)
```

## API Methods

| Method | Description |
|--------|-------------|
| `getCard(id:)` | Fetch a single card by ID |
| `listCards(boardId:)` | List all cards on a board |
| `getCardMembers(cardId:)` | Get members of a card |
| `listCustomProperties()` | List all custom property definitions |
| `getCustomProperty(id:)` | Get a single custom property definition |
| `getBoard(id:)` | Fetch a board by ID |
| `getBoardColumns(boardId:)` | Get columns for a board |
| `getBoardLanes(boardId:)` | Get lanes for a board |
| `listSpaces()` | List all spaces |
| `listBoards(spaceId:)` | List boards in a space |

## Error Handling

All methods throw `KaitenError`, which provides typed cases for every failure mode:

```swift
do {
    let card = try await client.getCard(id: 999)
} catch let error as KaitenError {
    switch error {
    case .missingConfiguration(let key):
        print("Missing config: \(key)")
    case .invalidURL(let url):
        print("Bad URL: \(url)")
    case .unauthorized:
        print("Check your API token")
    case .notFound(let resource, let id):
        print("\(resource) \(id) not found")
    case .rateLimited(let retryAfter):
        print("Rate limited, retry after: \(String(describing: retryAfter))")
    case .serverError(let statusCode, let body):
        print("Server error \(statusCode): \(body ?? "")")
    case .networkError(let underlying):
        print("Network: \(underlying)")
    case .unexpectedResponse(let statusCode):
        print("Unexpected HTTP \(statusCode)")
    }
}
```

## Configuration

Environment variables are resolved via [swift-configuration](https://github.com/apple/swift-configuration):

| Variable | Description |
|----------|-------------|
| `KAITEN_URL` | Base URL of the Kaiten API (e.g. `https://your-company.kaiten.ru/api/latest`) |
| `KAITEN_TOKEN` | Bearer token for authentication |

## License

See [LICENSE](LICENSE) for details.
