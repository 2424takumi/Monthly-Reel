import XCTest
@testable import MonthlyReel

final class YearMonthTests: XCTestCase {

    // MARK: - displayString

    func test_displayString_formatsWithLeadingZeros() {
        // Arrange
        let ym = YearMonth(year: 2026, month: 1)

        // Act
        let result = ym.displayString

        // Assert
        XCTAssertEqual(result, "2026.01")
    }

    func test_displayString_twoDigitMonth() {
        let ym = YearMonth(year: 2026, month: 12)
        XCTAssertEqual(ym.displayString, "2026.12")
    }

    // MARK: - startDate / endDate range correctness

    func test_startDate_isFirstMomentOfMonth() {
        // Arrange
        let ym = YearMonth(year: 2026, month: 3)
        let cal = Calendar.current

        // Act
        let start = ym.startDate

        // Assert
        XCTAssertEqual(cal.component(.year, from: start), 2026)
        XCTAssertEqual(cal.component(.month, from: start), 3)
        XCTAssertEqual(cal.component(.day, from: start), 1)
        XCTAssertEqual(cal.component(.hour, from: start), 0)
        XCTAssertEqual(cal.component(.minute, from: start), 0)
        XCTAssertEqual(cal.component(.second, from: start), 0)
    }

    func test_endDate_isLastMomentOfMonth() {
        // Arrange
        let ym = YearMonth(year: 2026, month: 3)
        let cal = Calendar.current

        // Act
        let end = ym.endDate

        // Assert
        XCTAssertEqual(cal.component(.year, from: end), 2026)
        XCTAssertEqual(cal.component(.month, from: end), 3)
        XCTAssertEqual(cal.component(.day, from: end), 31)
        XCTAssertEqual(cal.component(.hour, from: end), 23)
        XCTAssertEqual(cal.component(.minute, from: end), 59)
        XCTAssertEqual(cal.component(.second, from: end), 59)
    }

    func test_endDate_february_nonLeapYear() {
        // Arrange
        let ym = YearMonth(year: 2025, month: 2)
        let cal = Calendar.current

        // Act
        let end = ym.endDate

        // Assert
        XCTAssertEqual(cal.component(.day, from: end), 28)
    }

    func test_endDate_february_leapYear() {
        // Arrange
        let ym = YearMonth(year: 2024, month: 2)
        let cal = Calendar.current

        // Act
        let end = ym.endDate

        // Assert
        XCTAssertEqual(cal.component(.day, from: end), 29)
    }

    func test_startDate_endDate_sameMonthRange() {
        // Arrange
        let ym = YearMonth(year: 2026, month: 6)

        // Act & Assert
        XCTAssertTrue(ym.startDate < ym.endDate)
    }

    // MARK: - next / previous (December -> January boundary)

    func test_next_december_becomesJanuaryNextYear() {
        // Arrange
        let dec = YearMonth(year: 2025, month: 12)

        // Act
        let jan = dec.next

        // Assert
        XCTAssertEqual(jan.year, 2026)
        XCTAssertEqual(jan.month, 1)
    }

    func test_next_normalMonth_incrementsMonth() {
        let ym = YearMonth(year: 2026, month: 5)
        let result = ym.next
        XCTAssertEqual(result.year, 2026)
        XCTAssertEqual(result.month, 6)
    }

    func test_previous_january_becomesDecemberPreviousYear() {
        // Arrange
        let jan = YearMonth(year: 2026, month: 1)

        // Act
        let dec = jan.previous

        // Assert
        XCTAssertEqual(dec.year, 2025)
        XCTAssertEqual(dec.month, 12)
    }

    func test_previous_normalMonth_decrementsMonth() {
        let ym = YearMonth(year: 2026, month: 7)
        let result = ym.previous
        XCTAssertEqual(result.year, 2026)
        XCTAssertEqual(result.month, 6)
    }

    // MARK: - Comparable

    func test_comparable_sameYearDifferentMonth() {
        let earlier = YearMonth(year: 2026, month: 1)
        let later = YearMonth(year: 2026, month: 12)
        XCTAssertTrue(earlier < later)
        XCTAssertFalse(later < earlier)
    }

    func test_comparable_differentYear() {
        let earlier = YearMonth(year: 2025, month: 12)
        let later = YearMonth(year: 2026, month: 1)
        XCTAssertTrue(earlier < later)
    }

    func test_comparable_equal() {
        let a = YearMonth(year: 2026, month: 2)
        let b = YearMonth(year: 2026, month: 2)
        XCTAssertFalse(a < b)
        XCTAssertFalse(b < a)
        XCTAssertEqual(a, b)
    }

    // MARK: - Codable

    func test_codable_roundTrip() throws {
        // Arrange
        let original = YearMonth(year: 2026, month: 2)

        // Act
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(YearMonth.self, from: data)

        // Assert
        XCTAssertEqual(original, decoded)
    }

    // MARK: - Hashable

    func test_hashable_sameValuesHaveSameHash() {
        let a = YearMonth(year: 2026, month: 2)
        let b = YearMonth(year: 2026, month: 2)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func test_hashable_canBeUsedAsDictionaryKey() {
        let ym = YearMonth(year: 2026, month: 2)
        var dict: [YearMonth: String] = [:]
        dict[ym] = "test"
        XCTAssertEqual(dict[ym], "test")
    }

    // MARK: - current

    func test_current_returnsCurrentYearAndMonth() {
        let now = Date()
        let cal = Calendar.current
        let current = YearMonth.current
        XCTAssertEqual(current.year, cal.component(.year, from: now))
        XCTAssertEqual(current.month, cal.component(.month, from: now))
    }
}
