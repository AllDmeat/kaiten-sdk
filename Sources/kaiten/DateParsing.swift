import Foundation

/// ISO 8601 date format used across the CLI.
///
/// Accepts both full datetime (`2025-01-15T10:30:00Z`) and date-only (`2025-01-15`).
enum DateParsing {
    private static let iso8601Full: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let dateOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    /// Parses an ISO 8601 string into a `Date`.
    ///
    /// - Parameter string: Date string in `yyyy-MM-dd` or `yyyy-MM-ddTHH:mm:ssZ` format.
    /// - Throws: `ValidationError` if the string cannot be parsed.
    /// - Returns: The parsed `Date`.
    static func parse(_ string: String) throws -> Date {
        if let date = iso8601Full.date(from: string) {
            return date
        }
        if let date = dateOnly.date(from: string) {
            return date
        }
        throw ValidationError("Invalid date: '\(string)'. Expected ISO 8601 format (e.g. 2025-01-15 or 2025-01-15T10:30:00Z)")
    }

    /// Parses an optional date string.
    static func parse(_ string: String?) throws -> Date? {
        guard let string else { return nil }
        return try parse(string)
    }
}

import ArgumentParser

extension ValidationError: @retroactive @unchecked Sendable {}
