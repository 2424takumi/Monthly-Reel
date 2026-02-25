import Foundation

/// Value type representing a year and month pair.
/// Used throughout the app to identify which month a reel belongs to.
struct YearMonth: Codable, Hashable, Comparable {
    let year: Int
    let month: Int

    static var current: YearMonth {
        let now = Date()
        let cal = Calendar.current
        return YearMonth(
            year: cal.component(.year, from: now),
            month: cal.component(.month, from: now)
        )
    }

    var displayString: String {
        String(format: "%04d.%02d", year, month)
    }

    /// The first moment of this month (00:00:00 on the 1st day).
    var startDate: Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        guard let date = Calendar.current.date(from: components) else {
            fatalError("Invalid YearMonth: \(year)-\(month)")
        }
        return date
    }

    /// The last moment of this month (23:59:59 on the last day).
    var endDate: Date {
        let cal = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        guard let firstDay = cal.date(from: components) else {
            fatalError("Invalid YearMonth: \(year)-\(month)")
        }
        guard let nextMonth = cal.date(byAdding: .month, value: 1, to: firstDay) else {
            fatalError("Could not compute next month for \(year)-\(month)")
        }
        guard let lastMoment = cal.date(byAdding: .second, value: -1, to: nextMonth) else {
            fatalError("Could not compute end date for \(year)-\(month)")
        }
        return lastMoment
    }

    /// Returns the next month (e.g., December 2025 -> January 2026).
    var next: YearMonth {
        if month == 12 {
            return YearMonth(year: year + 1, month: 1)
        }
        return YearMonth(year: year, month: month + 1)
    }

    /// Returns the previous month (e.g., January 2026 -> December 2025).
    var previous: YearMonth {
        if month == 1 {
            return YearMonth(year: year - 1, month: 12)
        }
        return YearMonth(year: year, month: month - 1)
    }

    static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        lhs.year != rhs.year ? lhs.year < rhs.year : lhs.month < rhs.month
    }
}
