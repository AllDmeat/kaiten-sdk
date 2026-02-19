import Foundation
import Testing

@testable import KaitenSDK

@Suite("Pagination")
struct PaginationTests {
  private enum StubError: Error {
    case laterPageFailed
  }

  private actor CallCounter {
    private(set) var count = 0
    func increment() { count += 1 }
  }

  private func collect<T: Sendable>(_ stream: AsyncThrowingStream<T, Error>) async throws -> [T] {
    var result: [T] = []
    for try await item in stream {
      result.append(item)
    }
    return result
  }

  @Test("allPages yields all items in order across multiple pages")
  func multiPageOrder() async throws {
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest",
      token: "test-token",
      transport: MockClientTransport.returning(statusCode: 200, body: "[]")
    )

    let stream: AsyncThrowingStream<Int, Error> = client.allPages(pageSize: 2) {
      (offset: Int, limit: Int) async throws -> Page<Int> in
      #expect(limit == 2)
      switch offset {
      case 0: return Page(items: [1, 2], offset: offset, limit: limit)
      case 2: return Page(items: [3, 4], offset: offset, limit: limit)
      case 4: return Page(items: [5], offset: offset, limit: limit)
      default: return Page(items: [], offset: offset, limit: limit)
      }
    }

    let items = try await collect(stream)
    #expect(items == [1, 2, 3, 4, 5])
  }

  @Test("allPages completes immediately for empty first page")
  func emptyFirstPage() async throws {
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest",
      token: "test-token",
      transport: MockClientTransport.returning(statusCode: 200, body: "[]")
    )

    let stream: AsyncThrowingStream<Int, Error> = client.allPages(pageSize: 10) {
      (offset: Int, limit: Int) async throws -> Page<Int> in
      Page(items: [Int](), offset: offset, limit: limit)
    }

    let items = try await collect(stream)
    #expect(items.isEmpty)
  }

  @Test("allPages stops on a single partial page")
  func singlePartialPage() async throws {
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest",
      token: "test-token",
      transport: MockClientTransport.returning(statusCode: 200, body: "[]")
    )

    let stream: AsyncThrowingStream<Int, Error> = client.allPages(pageSize: 5) {
      (offset: Int, limit: Int) async throws -> Page<Int> in
      Page(items: [42], offset: offset, limit: limit)
    }

    let items = try await collect(stream)
    #expect(items == [42])
  }

  @Test("allPages propagates an error from a later page")
  func laterPageFailure() async throws {
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest",
      token: "test-token",
      transport: MockClientTransport.returning(statusCode: 200, body: "[]")
    )

    let stream: AsyncThrowingStream<Int, Error> = client.allPages(pageSize: 2) {
      (offset: Int, limit: Int) async throws -> Page<Int> in
      if offset == 0 {
        return Page(items: [1, 2], offset: offset, limit: limit)
      }
      throw StubError.laterPageFailed
    }

    var collected: [Int] = []
    await #expect(throws: StubError.self) {
      for try await item in stream {
        collected.append(item)
      }
    }
    #expect(collected == [1, 2])
  }

  @Test("allPages stops after stream cancellation")
  func cancellationStopsPagination() async throws {
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest",
      token: "test-token",
      transport: MockClientTransport.returning(statusCode: 200, body: "[]")
    )

    let counter = CallCounter()
    let stream: AsyncThrowingStream<Int, Error> = client.allPages(pageSize: 1) {
      (offset: Int, limit: Int) async throws -> Page<Int> in
      await counter.increment()
      if offset > 0 {
        try await Task.sleep(nanoseconds: 100_000_000)
      }
      return Page(items: [offset + 1], offset: offset, limit: limit)
    }

    let consumer = Task {
      for try await _ in stream {
        break
      }
    }
    try await consumer.value
    try await Task.sleep(nanoseconds: 50_000_000)

    let totalCalls = await counter.count
    #expect(totalCalls <= 3)
  }
}
