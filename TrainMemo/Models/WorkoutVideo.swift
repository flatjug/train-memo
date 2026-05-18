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
            WorkoutVideo(
                order: $0,
                title: "動画 \($0 + 1)",
                youtubeURL: placeholderURL,
                durationMinutes: defaultDurationMinutes
            )
        }
    }
}
