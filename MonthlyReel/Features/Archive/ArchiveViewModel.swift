import Foundation

/// View model for the Archive screen.
/// Loads and manages the collection of previously generated reels.
@Observable
@MainActor
final class ArchiveViewModel {

    // MARK: - Dependencies

    private let videoArchiveRepository: VideoArchiveRepositoryProtocol

    // MARK: - State

    var reels: [MonthlyReelModel] = []

    // MARK: - Init

    init(videoArchiveRepository: VideoArchiveRepositoryProtocol) {
        self.videoArchiveRepository = videoArchiveRepository
    }

    // MARK: - Actions

    /// Fetches all saved reels from the archive, sorted newest first.
    func loadReels() {
        do {
            reels = try videoArchiveRepository.fetchAll()
                .sorted { lhs, rhs in
                    let lhsMonth = YearMonth(year: lhs.year, month: lhs.month)
                    let rhsMonth = YearMonth(year: rhs.year, month: rhs.month)
                    return lhsMonth > rhsMonth
                }
        } catch {
            reels = []
        }
    }

    /// Deletes a single reel from the archive and refreshes the list.
    func deleteReel(_ reel: MonthlyReelModel) {
        do {
            try videoArchiveRepository.delete(reel)
            loadReels()
        } catch {
            // Silently fail — the reel stays in the list until next refresh.
        }
    }
}
