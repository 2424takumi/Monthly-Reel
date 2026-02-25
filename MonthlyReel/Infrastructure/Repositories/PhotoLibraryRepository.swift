import Photos
import OSLog

/// Concrete PhotoKit-backed implementation.
final class PhotoLibraryRepository: PhotoLibraryRepositoryProtocol {

    // MARK: - Constants

    private let maxVideoCount = 200

    // MARK: - Authorization

    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    // MARK: - Fetching

    func fetchVideos(in month: YearMonth) async throws -> [PHAsset] {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            throw AppError.photoLibraryAccessDenied
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(
            format: "mediaType == %d AND creationDate >= %@ AND creationDate <= %@",
            PHAssetMediaType.video.rawValue,
            month.startDate as NSDate,
            month.endDate as NSDate
        )
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true)
        ]

        let result = PHAsset.fetchAssets(with: fetchOptions)

        guard result.count > 0 else {
            throw AppError.noVideosInMonth(month: month)
        }

        let count = min(result.count, maxVideoCount)
        if result.count > maxVideoCount {
            Logger.scanning.warning(
                "Video count \(result.count) exceeds max \(self.maxVideoCount), truncating"
            )
        }

        var assets: [PHAsset] = []
        assets.reserveCapacity(count)
        result.enumerateObjects { asset, index, stop in
            if index >= count {
                stop.pointee = true
                return
            }
            assets.append(asset)
        }

        Logger.scanning.info("Found \(assets.count) videos in \(month.displayString)")
        return assets
    }
}
