import Foundation

/// Protocol for reel persistence (SwiftData).
/// Provides CRUD operations for MonthlyReelModel instances.
protocol VideoArchiveRepositoryProtocol {
    func save(reel: MonthlyReelModel) throws
    func fetch(year: Int, month: Int) throws -> MonthlyReelModel?
    func fetchAll() throws -> [MonthlyReelModel]
    func delete(reel: MonthlyReelModel) throws
    func deleteAll() throws
}
