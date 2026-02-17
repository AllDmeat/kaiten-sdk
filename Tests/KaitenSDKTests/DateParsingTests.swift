import Foundation
import Testing

@testable import kaiten

@Suite("DateParsing")
struct DateParsingTests {
    @Test("Parses full ISO 8601 datetime")
    func fullISO8601() throws {
        let date = try DateParsing.parse("2025-01-15T10:30:00Z")
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
        #expect(components.year == 2025)
        #expect(components.month == 1)
        #expect(components.day == 15)
        #expect(components.hour == 10)
        #expect(components.minute == 30)
    }

    @Test("Parses date-only string")
    func dateOnly() throws {
        let date = try DateParsing.parse("2025-01-15")
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
        #expect(components.year == 2025)
        #expect(components.month == 1)
        #expect(components.day == 15)
    }

    @Test("Throws on invalid date string")
    func invalidDate() {
        #expect(throws: Error.self) {
            try DateParsing.parse("not-a-date")
        }
    }

    @Test("Throws on empty string")
    func emptyString() {
        #expect(throws: Error.self) {
            try DateParsing.parse("")
        }
    }

    @Test("Optional parse returns nil for nil input")
    func optionalNil() throws {
        let result = try DateParsing.parse(nil as String?)
        #expect(result == nil)
    }

    @Test("Optional parse returns date for valid input")
    func optionalValid() throws {
        let result = try DateParsing.parse("2025-06-01" as String?)
        #expect(result != nil)
    }
}
