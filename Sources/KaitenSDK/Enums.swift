// MARK: - Type-Safe Enums for Kaiten API
//
// These enums replace magic integer literals in the public API.
// Values are sourced from the Kaiten API documentation:
// https://developers.kaiten.ru

/// Card condition on a board.
///
/// Used in ``KaitenClient/CardFilter``, ``KaitenClient/updateCard(id:...)``.
/// - SeeAlso: [Kaiten API – Cards](https://developers.kaiten.ru/cards/retrieve-card-list)
public enum CardCondition: Int, Sendable, CaseIterable {
  /// Card is on the board (active).
  case onBoard = 1
  /// Card is archived.
  case archived = 2
}

/// Lane condition (includes deleted state).
///
/// Used in ``KaitenClient/getBoardLanes(boardId:condition:)``
/// and ``KaitenClient/updateLane(boardId:id:...)``.
/// - SeeAlso: [Kaiten API – Lanes](https://developers.kaiten.ru/lanes/get-list-of-lanes)
public enum LaneCondition: Int, Sendable, CaseIterable {
  /// Lane is live (active).
  case live = 1
  /// Lane is archived.
  case archived = 2
  /// Lane is deleted.
  case deleted = 3
}

/// Card workflow state.
///
/// Used in ``KaitenClient/CardFilter`` (`states` parameter).
/// - SeeAlso: [Kaiten API – Cards](https://developers.kaiten.ru/cards/retrieve-card-list)
public enum CardState: Int, Sendable, CaseIterable {
  /// Card is queued (not yet started).
  case queued = 1
  /// Card is in progress.
  case inProgress = 2
  /// Card is done.
  case done = 3
}

/// Card member role type.
///
/// Used in ``KaitenClient/updateCardMemberRole(cardId:userId:type:)``.
/// - SeeAlso: [Kaiten API – Card Members](https://developers.kaiten.ru/cards/update-card)
public enum CardMemberRoleType: Int, Sendable, CaseIterable {
  /// Regular member.
  case member = 1
  /// Responsible person for the card.
  case responsible = 2
}

/// Text format for card description.
///
/// Used in ``KaitenClient/createCard(...)`` and ``KaitenClient/updateCard(id:...)``.
/// - SeeAlso: [Kaiten API – Create Card](https://developers.kaiten.ru/cards/create-card)
public enum TextFormatType: Int, Sendable, CaseIterable {
  /// Markdown format (default).
  case markdown = 1
  /// HTML format.
  case html = 2
  /// Jira Wiki format.
  case jiraWiki = 3
}

/// Card position within a cell.
///
/// Overrides `sort_order` if present.
/// - SeeAlso: [Kaiten API – Create Card](https://developers.kaiten.ru/cards/create-card)
public enum CardPosition: Int, Sendable, CaseIterable {
  /// First in cell.
  case first = 1
  /// Last in cell.
  case last = 2
}

/// Column type (workflow stage).
///
/// Used in ``KaitenClient/createColumn(...)`` and ``KaitenClient/updateColumn(...)``.
/// - SeeAlso: [Kaiten API – Columns](https://developers.kaiten.ru/columns/create-column)
public enum ColumnType: Int, Sendable, CaseIterable {
  /// Queue column.
  case queue = 1
  /// In-progress column.
  case inProgress = 2
  /// Done column.
  case done = 3
}

/// WIP limit counting type.
///
/// Used in column and lane creation/update.
/// - SeeAlso: [Kaiten API – Columns](https://developers.kaiten.ru/columns/create-column)
public enum WipLimitType: Int, Sendable, CaseIterable {
  /// Limit by card count.
  case cardCount = 1
  /// Limit by card size.
  case cardSize = 2
}
