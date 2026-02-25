import Foundation
@testable import MonthlyReel

/// Mock implementation of VideoAssetProtocol for unit testing.
/// Allows configurable identifier, duration, and creation date
/// without depending on PHAsset.
struct MockVideoAsset: VideoAssetProtocol {
    let localIdentifier: String
    let duration: TimeInterval
    let creationDate: Date?

    init(
        id: String = UUID().uuidString,
        duration: TimeInterval = 10.0,
        creationDate: Date = Date()
    ) {
        self.localIdentifier = id
        self.duration = duration
        self.creationDate = creationDate
    }
}

// MARK: - Factory Helpers

extension MockVideoAsset {

    /// Creates an asset with a specific date offset from a base date.
    static func asset(
        id: String = UUID().uuidString,
        duration: TimeInterval = 10.0,
        daysFromNow: Int = 0
    ) -> MockVideoAsset {
        let date = Calendar.current.date(
            byAdding: .day,
            value: daysFromNow,
            to: Date()
        ) ?? Date()
        return MockVideoAsset(
            id: id,
            duration: duration,
            creationDate: date
        )
    }

    /// Creates multiple assets on distinct days.
    static func distinctDayAssets(count: Int) -> [MockVideoAsset] {
        (0..<count).map { index in
            asset(
                id: "asset-\(index)",
                duration: 10.0,
                daysFromNow: -index
            )
        }
    }

    /// Creates multiple assets all on the same day.
    static func sameDayAssets(
        count: Int,
        date: Date = Date()
    ) -> [MockVideoAsset] {
        (0..<count).map { index in
            MockVideoAsset(
                id: "same-day-\(index)",
                duration: 10.0,
                creationDate: date
            )
        }
    }
}
