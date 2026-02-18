// Maps OpenAPI-generated Output enums to the unified ResponseCase type.
// Each extension converts operation-specific cases into a common shape,
// eliminating repetitive switch boilerplate in KaitenClient methods.

// MARK: - Cards

extension Operations.get_cards.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.get_cards.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .unauthorized: .unauthorized
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

extension Operations.create_card.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.create_card.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .badRequest: .undocumented(statusCode: 400)
    case .unauthorized: .unauthorized
    case .forbidden: .forbidden
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

extension Operations.get_card.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.get_card.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .unauthorized: .unauthorized
    case .notFound: .notFound
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

extension Operations.update_card.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.update_card.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .badRequest: .undocumented(statusCode: 400)
    case .unauthorized: .unauthorized
    case .forbidden: .forbidden
    case .notFound: .notFound
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

// MARK: - Card Members & Comments

extension Operations.retrieve_list_of_card_members.Output {
  func toCase()
    -> KaitenClient.ResponseCase<Operations.retrieve_list_of_card_members.Output.Ok.Body>
  {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .unauthorized: .unauthorized
    case .forbidden: .forbidden
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

extension Operations.retrieve_card_comments.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.retrieve_card_comments.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .unauthorized: .unauthorized
    case .forbidden: .forbidden
    case .notFound: .notFound
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

extension Operations.create_card_comment.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.create_card_comment.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .unauthorized: .unauthorized
    case .forbidden: .forbidden
    case .notFound: .notFound
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

extension Operations.update_card_comment.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.update_card_comment.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .unauthorized: .unauthorized
    case .forbidden: .forbidden
    case .notFound: .notFound
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

// MARK: - Checklists

extension Operations.create_checklist.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.create_checklist.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .unauthorized: .unauthorized
    case .forbidden: .forbidden
    case .notFound: .notFound
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

extension Operations.get_checklist.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.get_checklist.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .unauthorized: .unauthorized
    case .forbidden: .forbidden
    case .notFound: .notFound
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

extension Operations.remove_checklist.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.remove_checklist.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .unauthorized: .unauthorized
    case .forbidden: .forbidden
    case .notFound: .notFound
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

// MARK: - Checklist Items

extension Operations.update_checklist_item.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.update_checklist_item.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .unauthorized: .unauthorized
    case .forbidden: .forbidden
    case .notFound: .notFound
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

// MARK: - Custom Properties

extension Operations.get_list_of_properties.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.get_list_of_properties.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .unauthorized: .unauthorized
    case .forbidden: .forbidden
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

extension Operations.get_property.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.get_property.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .unauthorized: .unauthorized
    case .forbidden: .forbidden
    case .notFound: .notFound
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

// MARK: - Boards

extension Operations.get_board.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.get_board.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .unauthorized: .unauthorized
    case .forbidden: .forbidden
    case .notFound: .notFound
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

extension Operations.get_list_of_columns.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.get_list_of_columns.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .unauthorized: .unauthorized
    case .forbidden: .forbidden
    case .notFound: .notFound
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

extension Operations.get_list_of_lanes.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.get_list_of_lanes.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .unauthorized: .unauthorized
    case .forbidden: .forbidden
    case .notFound: .notFound
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

// MARK: - Spaces

extension Operations.retrieve_list_of_spaces.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.retrieve_list_of_spaces.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .unauthorized: .unauthorized
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}

extension Operations.get_list_of_boards.Output {
  func toCase() -> KaitenClient.ResponseCase<Operations.get_list_of_boards.Output.Ok.Body> {
    switch self {
    case .ok(let ok): .ok(ok.body)
    case .unauthorized: .unauthorized
    case .forbidden: .forbidden
    case .notFound: .notFound
    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)
    }
  }
}
