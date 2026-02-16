# KaitenSDK

[![Build](https://github.com/AllDmeat/KaitenSDK/actions/workflows/ci.yml/badge.svg)](https://github.com/AllDmeat/KaitenSDK/actions/workflows/ci.yml)

Swift SDK for the [Kaiten](https://kaiten.ru) project management API. OpenAPI-generated types with typed errors, automatic retry on `429 Too Many Requests`, and Bearer token authentication.

## Requirements

- Swift 6.2+
- macOS 15+ (ARM) / Linux (x86-64, ARM)

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

### As a library

```swift
import KaitenSDK

let client = try KaitenClient(
    baseURL: "https://your-company.kaiten.ru/api/latest",
    token: "your-api-token"
)

let spaces = try await client.listSpaces()
let cards = try await client.listCards(boardId: 42)
let card = try await client.getCard(id: 123)
```

### CLI Installation

#### mise (recommended)

[mise](https://mise.jdx.dev) — менеджер инструментов. Установит нужную версию автоматически:

```bash
mise use -g ubi:AllDmeat/KaitenSDK --rename kaiten
```

#### GitHub Release

Скачайте бинарь для вашей платформы со [страницы релизов](https://github.com/AllDmeat/KaitenSDK/releases).

#### Из исходников

```bash
swift build -c release
# Бинарь: .build/release/kaiten
```

### As a CLI

The CLI resolves credentials in order: flags → config file.

**Option 1 — Config file** (recommended):

Create `~/.config/kaiten-mcp/config.json`:

```json
{
  "url": "https://your-company.kaiten.ru/api/latest",
  "token": "your-api-token"
}
```

Then run commands without flags:

```bash
kaiten list-spaces
kaiten get-card --id 123
```

**Option 2 — Flags** (override config file):

```bash
kaiten list-spaces \
  --url "https://your-company.kaiten.ru/api/latest" \
  --token "your-api-token"
```

## CLI Commands

Every command accepts `--url` and `--token` flags to override the config file.

| Command | Flags | Description |
|---------|-------|-------------|
| `list-spaces` | — | List all spaces |
| `list-boards` | `--space-id` | List boards in a space |
| `get-board` | `--id` | Get a board by ID |
| `get-board-columns` | `--board-id` | Get columns of a board |
| `get-board-lanes` | `--board-id` | Get lanes of a board |
| `list-cards` | `--board-id` | List all cards on a board |
| `get-card` | `--id` | Get a card by ID |
| `get-card-members` | `--card-id` | Get members of a card |
| `list-custom-properties` | — | List all custom property definitions |
| `get-custom-property` | `--id` | Get a custom property by ID |

All output is pretty-printed JSON.

## SDK API Methods

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

## Configuration

The `KaitenClient` initializer takes explicit parameters:

```swift
public init(baseURL: String, token: String) throws
```

The CLI uses [swift-configuration](https://github.com/apple/swift-configuration) with `FileProvider<JSONSnapshot>` to read `~/.config/kaiten-mcp/config.json`. The `--url` and `--token` flags take priority over the config file.

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

## License

See [LICENSE](LICENSE) for details.
