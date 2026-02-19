import Foundation
import Testing

@testable import KaitenSDK

@Suite("Page")
struct PageTests {
  private struct EncodedPage<T: Decodable>: Decodable {
    let items: [T]
    let offset: Int
    let limit: Int
    let hasMore: Bool
  }

  @Test("hasMore is true when items count equals limit")
  func hasMoreWhenFull() {
    let page = Page(items: [1, 2], offset: 0, limit: 2)
    #expect(page.hasMore == true)
  }

  @Test("hasMore is false when items count is less than limit")
  func hasMoreWhenPartial() {
    let page = Page(items: [1], offset: 0, limit: 2)
    #expect(page.hasMore == false)
  }

  @Test("empty page has no items and no more pages")
  func emptyPage() {
    let page = Page(items: [Int](), offset: 20, limit: 50)
    #expect(page.items.isEmpty)
    #expect(page.hasMore == false)
    #expect(page.offset == 20)
    #expect(page.limit == 50)
  }

  @Test("Page supports Equatable when item type is Equatable")
  func equatable() {
    let lhs = Page(items: [1, 2, 3], offset: 0, limit: 3)
    let rhs = Page(items: [1, 2, 3], offset: 0, limit: 3)
    let different = Page(items: [1, 2], offset: 0, limit: 3)
    #expect(lhs == rhs)
    #expect(lhs != different)
  }

  @Test("Page supports encoding round-trip of encoded fields")
  func encodingRoundTrip() throws {
    let page = Page(items: [1, 2], offset: 10, limit: 2)
    let data = try JSONEncoder().encode(page)
    let decoded = try JSONDecoder().decode(EncodedPage<Int>.self, from: data)

    #expect(decoded.items == [1, 2])
    #expect(decoded.offset == 10)
    #expect(decoded.limit == 2)
    #expect(decoded.hasMore == true)
  }
}
