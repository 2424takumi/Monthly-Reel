import Foundation

/// App-wide constants used across all layers.
enum Constants {
    static let maxVideoScanCount = 200
    static let defaultClipDuration: Double = 3.0

    enum ClipCount {
        static func maxClips(forVideoCount count: Int) -> Int {
            switch count {
            case 1...5:   return count
            case 6...20:  return 10
            case 21...50: return 15
            default:      return 20
            }
        }
    }

    enum Storage {
        static let reelsDirectory = "Reels"
        static let thumbnailsDirectory = "Thumbnails"

        static func reelFilename(year: Int, month: Int) -> String {
            String(format: "%04d-%02d.mp4", year, month)
        }

        static func thumbnailFilename(year: Int, month: Int) -> String {
            String(format: "%04d-%02d.jpg", year, month)
        }
    }
}
