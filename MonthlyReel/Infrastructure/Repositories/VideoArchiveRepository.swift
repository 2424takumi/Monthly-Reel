import SwiftData
import Foundation
import OSLog

/// Abstraction for persisting and retrieving monthly reel records.
/// Uses SwiftData for metadata and FileManager for associated video/thumbnail files.
protocol VideoArchiveRepositoryProtocol {
    func save(reel: MonthlyReelModel) throws
    func fetch(year: Int, month: Int) throws -> MonthlyReelModel?
    func fetchAll() throws -> [MonthlyReelModel]
    func delete(reel: MonthlyReelModel) throws
    func deleteAll() throws
}

/// Concrete SwiftData-backed implementation.
final class VideoArchiveRepository: VideoArchiveRepositoryProtocol {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Save

    func save(reel: MonthlyReelModel) throws {
        modelContext.insert(reel)
        try modelContext.save()
        Logger.storage.info("Saved reel for \(reel.year)-\(reel.month)")
    }

    // MARK: - Fetch

    func fetch(year: Int, month: Int) throws -> MonthlyReelModel? {
        let predicate = #Predicate<MonthlyReelModel> { reel in
            reel.year == year && reel.month == month
        }
        let descriptor = FetchDescriptor<MonthlyReelModel>(predicate: predicate)
        let results = try modelContext.fetch(descriptor)
        return results.first
    }

    func fetchAll() throws -> [MonthlyReelModel] {
        let descriptor = FetchDescriptor<MonthlyReelModel>(
            sortBy: [
                SortDescriptor(\.year, order: .reverse),
                SortDescriptor(\.month, order: .reverse)
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Delete

    func delete(reel: MonthlyReelModel) throws {
        removeAssociatedFiles(for: reel)
        modelContext.delete(reel)
        try modelContext.save()
        Logger.storage.info("Deleted reel for \(reel.year)-\(reel.month)")
    }

    func deleteAll() throws {
        let allReels = try fetchAll()
        for reel in allReels {
            removeAssociatedFiles(for: reel)
            modelContext.delete(reel)
        }
        try modelContext.save()
        Logger.storage.info("Deleted all reels")
    }
}

// MARK: - File Cleanup

private extension VideoArchiveRepository {

    func removeAssociatedFiles(for reel: MonthlyReelModel) {
        if let videoURL = reel.videoURL {
            try? FileManager.default.removeItem(at: videoURL)
        }
    }
}

// MARK: - Storage Directory Management

extension VideoArchiveRepository {

    /// Directory for exported reel video files.
    static var reelsDirectoryURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        return appSupport.appendingPathComponent("Reels", isDirectory: true)
    }

    /// Directory for reel thumbnail images.
    static var thumbnailsDirectoryURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        return appSupport.appendingPathComponent("Thumbnails", isDirectory: true)
    }

    /// Creates the Reels and Thumbnails directories if they do not already exist.
    static func ensureDirectoriesExist() throws {
        let fm = FileManager.default
        for directory in [reelsDirectoryURL, thumbnailsDirectoryURL] {
            if !fm.fileExists(atPath: directory.path) {
                try fm.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
            }
        }
    }
}
