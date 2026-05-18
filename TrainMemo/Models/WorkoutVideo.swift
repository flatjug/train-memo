import Foundation
import SwiftData

@Model
final class WorkoutVideo: Identifiable {
    static let defaultCount = 5
    static let defaultDurationMinutes = 10
    static let placeholderURL = "https://www.youtube.com/"

    @Attribute(.unique) var id: UUID
    var order: Int
    var title: String
    var youtubeURL: String
    var durationMinutes: Int

    init(
        id: UUID = UUID(),
        order: Int,
        title: String,
        youtubeURL: String,
        durationMinutes: Int
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.youtubeURL = youtubeURL
        self.durationMinutes = durationMinutes
    }

    static var defaults: [WorkoutVideo] {
        (0..<defaultCount).map {
            defaultVideo(order: $0)
        }
    }

    static func defaultVideo(order: Int) -> WorkoutVideo {
        WorkoutVideo(
            order: order,
            title: "動画 \(order + 1)",
            youtubeURL: placeholderURL,
            durationMinutes: defaultDurationMinutes
        )
    }

    static func youtubeURL(from string: String) -> URL? {
        guard
            let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines)),
            let scheme = url.scheme?.lowercased(),
            scheme == "https" || scheme == "http",
            let host = url.host?.lowercased()
        else {
            return nil
        }

        let isYouTubeHost = host == "youtube.com"
            || host.hasSuffix(".youtube.com")
            || host == "youtu.be"

        return isYouTubeHost ? url : nil
    }
}
