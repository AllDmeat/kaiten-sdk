# kaiten-sdk

[![Build](https://github.com/AllDmeat/kaiten-sdk/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/AllDmeat/kaiten-sdk/actions/workflows/build-and-test.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAllDmeat%2Fkaiten-sdk%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/AllDmeat/kaiten-sdk)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAllDmeat%2Fkaiten-sdk%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/AllDmeat/kaiten-sdk)

Swift SDK for the [Kaiten](https://kaiten.ru) project management API. OpenAPI-generated types with typed errors, automatic retry on `429 Too Many Requests`, and Bearer token authentication.

Full Kaiten API documentation: [developers.kaiten.ru](https://developers.kaiten.ru)

## Installation

### As a library

Add KaitenSDK to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/AllDmeat/kaiten-sdk.git", from: "0.1.0"),
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

### mise (recommended)

[mise](https://mise.jdx.dev) — a tool version manager. It will install the required version automatically:

```bash
mise use github:alldmeat/kaiten-sdk
```

### GitHub Release

Download the binary for your platform from the [releases page](https://github.com/AllDmeat/kaiten-sdk/releases).

### From Source

```bash
swift build -c release
# Binary: .build/release/kaiten
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

### As a CLI

The CLI resolves credentials in order: flags → config file.

#### 1. Get a Kaiten API Token

Get your API token at `https://<your-company>.kaiten.ru/profile/api-key`.

#### 2. Configure Credentials

**Option 1 — Config file** (recommended):

Create `~/.config/kaiten-mcp/config.json`:

```json
{
  "url": "https://<your-company>.kaiten.ru/api/latest",
  "token": "<your-api-token>"
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

## API Reference

### Cards

| Method | Description |
|--------|-------------|
| `listCards(boardId:)` | List all cards on a board |
| `getCard(id:)` | Fetch a single card by ID |
| `createCard(...)` | Create a new card |
| `updateCard(...)` | Update a card |
| `deleteCard(...)` | Delete a card |
| `listCardChildren(...)` | List child cards |
| `addCardChild(...)` | Add a child card |
| `removeCardChild(...)` | Remove a child card |
| `getCardMembers(cardId:)` | Get members of a card |
| `addCardMember(...)` | Add a member to a card |
| `updateCardMemberRole(...)` | Update a card member's role |
| `removeCardMember(...)` | Remove a member from a card |
| `getCardComments(cardId:)` | Get comments on a card |
| `createComment(cardId:text:)` | Add a comment to a card |
| `updateComment(...)` | Update a comment |
| `deleteComment(...)` | Delete a comment |
| `listCardTags(...)` | List tags on a card |
| `addCardTag(...)` | Add a tag to a card |
| `removeCardTag(...)` | Remove a tag from a card |
| `listCardBlockers(...)` | List card blockers |
| `createCardBlocker(...)` | Create a card blocker |
| `updateCardBlocker(...)` | Update a card blocker |
| `deleteCardBlocker(...)` | Delete a card blocker |
| `getCardLocationHistory(...)` | Get card location history |
| `getCardBaselines(...)` | Get card baselines |

### Checklists

| Method | Description |
|--------|-------------|
| `createChecklist(...)` | Create a checklist on a card |
| `getChecklist(...)` | Get a checklist |
| `updateChecklist(...)` | Update a checklist |
| `removeChecklist(...)` | Remove a checklist |
| `createChecklistItem(...)` | Create a checklist item |
| `updateChecklistItem(...)` | Update a checklist item |
| `removeChecklistItem(...)` | Remove a checklist item |

### External Links

| Method | Description |
|--------|-------------|
| `listExternalLinks(...)` | List external links on a card |
| `createExternalLink(...)` | Create an external link |
| `updateExternalLink(...)` | Update an external link |
| `removeExternalLink(...)` | Remove an external link |

### Spaces

| Method | Description |
|--------|-------------|
| `listSpaces()` | List all spaces |
| `createSpace(...)` | Create a space |
| `getSpace(...)` | Get a space by ID |
| `updateSpace(...)` | Update a space |
| `deleteSpace(...)` | Delete a space |

### Boards

| Method | Description |
|--------|-------------|
| `listBoards(spaceId:)` | List boards in a space |
| `getBoard(id:)` | Fetch a board by ID |
| `createBoard(...)` | Create a board |
| `updateBoard(...)` | Update a board |
| `deleteBoard(...)` | Delete a board |

### Columns

| Method | Description |
|--------|-------------|
| `getBoardColumns(boardId:)` | Get columns for a board |
| `createColumn(...)` | Create a column |
| `updateColumn(...)` | Update a column |
| `deleteColumn(...)` | Delete a column |
| `listSubcolumns(...)` | List subcolumns |
| `createSubcolumn(...)` | Create a subcolumn |
| `updateSubcolumn(...)` | Update a subcolumn |
| `deleteSubcolumn(...)` | Delete a subcolumn |

### Lanes

| Method | Description |
|--------|-------------|
| `getBoardLanes(boardId:)` | Get lanes for a board |
| `createLane(...)` | Create a lane |
| `updateLane(...)` | Update a lane |
| `deleteLane(...)` | Delete a lane |

### Custom Properties

| Method | Description |
|--------|-------------|
| `listCustomProperties()` | List all custom property definitions |
| `getCustomProperty(id:)` | Get a single custom property definition |

### Users

| Method | Description |
|--------|-------------|
| `listUsers()` | List all users |
| `getCurrentUser()` | Get the current user |

### Card Types & Sprints

| Method | Description |
|--------|-------------|
| `listCardTypes()` | List card types |
| `listSprints()` | List sprints |
| `getSprintSummary(...)` | Get sprint summary |

## Configuration

The CLI and MCP server share the same config file at `~/.config/kaiten-mcp/config.json` (see [Configure Credentials](#2-configure-credentials) above).

The `--url` and `--token` CLI flags take priority over the config file.

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

## Requirements

- Swift 6.2+
- macOS 15+ (ARM) / Linux (x86-64, ARM)

## License

See [LICENSE](LICENSE) for details.
