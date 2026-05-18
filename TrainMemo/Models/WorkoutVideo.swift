import Foundation
import SwiftData

@Model
final class WorkoutVideo: Identifiable {
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
        [
            WorkoutVideo(order: 0, title: "動画 1", youtubeURL: "https://www.youtube.com/", durationMinutes: 10),
            WorkoutVideo(order: 1, title: "動画 2", youtubeURL: "https://www.youtube.com/", durationMinutes: 10),
            WorkoutVideo(order: 2, title: "動画 3", youtubeURL: "https://www.youtube.com/", durationMinutes: 10),
            WorkoutVideo(order: 3, title: "動画 4", youtubeURL: "https://www.youtube.com/", durationMinutes: 10)
        ]
    }
}
