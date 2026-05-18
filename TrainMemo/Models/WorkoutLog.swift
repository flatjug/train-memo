import Foundation
import SwiftData

@Model
final class WorkoutLog: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var videoID: UUID
    var completedAt: Date

    init(id: UUID = UUID(), date: Date, videoID: UUID, completedAt: Date = Date()) {
        self.id = id
        self.date = date
        self.videoID = videoID
        self.completedAt = completedAt
    }
}
