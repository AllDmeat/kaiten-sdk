// MARK: - Type-Safe Enums for Kaiten API
//
// These enums replace magic integer literals in the public API.
// Values are sourced from the Kaiten API documentation:
// https://developers.kaiten.ru
//
// Each enum includes an `unknown(Int)` case for forward compatibility.
// If the API introduces new values, they are preserved as `.unknown(rawValue)`
// instead of being silently dropped.

/// Card condition on a board.
///
/// Used in ``KaitenClient/CardFilter`` and ``CardUpdateOptions``.
/// - SeeAlso: [Kaiten API – Cards](https://developers.kaiten.ru/cards/retrieve-card-list)
public enum CardCondition: Sendable, Equatable, CaseIterable, Codable {
  /// Card is on the board (active).
  case onBoard
  /// Card is archived.
  case archived
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [CardCondition] { [.onBoard, .archived] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .onBoard
    case 2: self = .archived
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .onBoard: 1
    case .archived: 2
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Lane condition (includes deleted state).
///
/// Used in ``KaitenClient/getBoardLanes(boardId:condition:)``
/// and ``KaitenClient/updateLane(boardId:id:...)``.
/// - SeeAlso: [Kaiten API – Lanes](https://developers.kaiten.ru/lanes/get-list-of-lanes)
public enum LaneCondition: Sendable, Equatable, CaseIterable, Codable {
  /// Lane is live (active).
  case live
  /// Lane is archived.
  case archived
  /// Lane is deleted.
  case deleted
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [LaneCondition] { [.live, .archived, .deleted] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .live
    case 2: self = .archived
    case 3: self = .deleted
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .live: 1
    case .archived: 2
    case .deleted: 3
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Card workflow state.
///
/// Used in ``KaitenClient/CardFilter`` (`states` parameter).
/// - SeeAlso: [Kaiten API – Cards](https://developers.kaiten.ru/cards/retrieve-card-list)
public enum CardState: Sendable, Equatable, CaseIterable, Codable {
  /// Card is queued (not yet started).
  case queued
  /// Card is in progress.
  case inProgress
  /// Card is done.
  case done
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [CardState] { [.queued, .inProgress, .done] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .queued
    case 2: self = .inProgress
    case 3: self = .done
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .queued: 1
    case .inProgress: 2
    case .done: 3
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Card member role type.
///
/// Used in ``KaitenClient/updateCardMemberRole(cardId:userId:type:)``.
/// - SeeAlso: [Kaiten API – Card Members](https://developers.kaiten.ru/cards/update-card)
public enum CardMemberRoleType: Sendable, Equatable, CaseIterable, Codable {
  /// Regular member.
  case member
  /// Responsible person for the card.
  case responsible
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [CardMemberRoleType] { [.member, .responsible] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .member
    case 2: self = .responsible
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .member: 1
    case .responsible: 2
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Text format for card description.
///
/// Used in ``CardCreateOptions`` and ``CardUpdateOptions``.
/// - SeeAlso: [Kaiten API – Create Card](https://developers.kaiten.ru/cards/create-card)
public enum TextFormatType: Sendable, Equatable, CaseIterable, Codable {
  /// Markdown format (default).
  case markdown
  /// HTML format.
  case html
  /// Jira Wiki format.
  case jiraWiki
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [TextFormatType] { [.markdown, .html, .jiraWiki] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .markdown
    case 2: self = .html
    case 3: self = .jiraWiki
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .markdown: 1
    case .html: 2
    case .jiraWiki: 3
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Card position within a cell.
///
/// Overrides `sort_order` if present.
/// - SeeAlso: [Kaiten API – Create Card](https://developers.kaiten.ru/cards/create-card)
public enum CardPosition: Sendable, Equatable, CaseIterable, Codable {
  /// First in cell.
  case first
  /// Last in cell.
  case last
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [CardPosition] { [.first, .last] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .first
    case 2: self = .last
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .first: 1
    case .last: 2
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Column type (workflow stage).
///
/// Used in ``KaitenClient/createColumn(...)`` and ``KaitenClient/updateColumn(...)``.
/// - SeeAlso: [Kaiten API – Columns](https://developers.kaiten.ru/columns/create-column)
public enum ColumnType: Sendable, Equatable, CaseIterable, Codable {
  /// Queue column.
  case queue
  /// In-progress column.
  case inProgress
  /// Done column.
  case done
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [ColumnType] { [.queue, .inProgress, .done] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .queue
    case 2: self = .inProgress
    case 3: self = .done
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .queue: 1
    case .inProgress: 2
    case .done: 3
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// WIP limit counting type.
///
/// Used in column and lane creation/update.
/// - SeeAlso: [Kaiten API – Columns](https://developers.kaiten.ru/columns/create-column)
public enum WipLimitType: Sendable, Equatable, CaseIterable, Codable {
  /// Limit by card count.
  case cardCount
  /// Limit by card size.
  case cardSize
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [WipLimitType] { [.cardCount, .cardSize] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .cardCount
    case 2: self = .cardSize
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .cardCount: 1
    case .cardSize: 2
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Card location history event condition.
///
/// Describes the board state at the time the movement event was recorded.
/// - SeeAlso: [Kaiten API – Card Location History](https://developers.kaiten.ru/cards/retrieve-card-location-history)
public enum CardHistoryCondition: Sendable, Equatable, CaseIterable, Codable {
  /// Card was on the board (active) at the time of the event.
  case active
  /// Card was archived at the time of the event.
  case archived
  /// Card was deleted at the time of the event.
  case deleted
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [CardHistoryCondition] { [.active, .archived, .deleted] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .active
    case 2: self = .archived
    case 3: self = .deleted
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .active: 1
    case .archived: 2
    case .deleted: 3
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
