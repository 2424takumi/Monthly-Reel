import SwiftData
import Foundation

/// SwiftData model representing a generated monthly highlight reel.
/// Each reel corresponds to a single year-month pair.
@Model
final class MonthlyReelModel {
    @Attribute(.unique) var id: UUID
    var year: Int
    var month: Int
    var createdAt: Date
    var updatedAt: Date
    var videoURL: URL?
    var thumbnailData: Data?
    var duration: Double        // seconds
    var clipCount: Int
    var appliedPreset: String   // ColorPreset.rawValue
    var sourceVideoCount: Int

    init(year: Int, month: Int) {
        self.id = UUID()
        self.year = year
        self.month = month
        self.createdAt = Date()
        self.updatedAt = Date()
        self.appliedPreset = ColorPreset.clean.rawValue
        self.duration = 0
        self.clipCount = 0
        self.sourceVideoCount = 0
    }
}
