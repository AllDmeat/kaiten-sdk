/// A page of results from a paginated API endpoint.
public struct Page<T: Sendable>: Sendable {
    /// The items in this page.
    public let items: [T]
    /// The offset used to fetch this page.
    public let offset: Int
    /// The limit used to fetch this page.
    public let limit: Int
    /// Whether there are likely more results available.
    /// Determined by `items.count == limit`.
    public let hasMore: Bool

    public init(items: [T], offset: Int, limit: Int) {
        self.items = items
        self.offset = offset
        self.limit = limit
        self.hasMore = items.count == limit
    }
}

extension Page: Equatable where T: Equatable {}
extension Page: Encodable where T: Encodable {}
