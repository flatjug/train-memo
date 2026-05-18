import Foundation
import SwiftData

@MainActor
enum AppBootstrapper {
    @discardableResult
    static func bootstrap(context: ModelContext) -> (settings: AppSettings, videos: [WorkoutVideo])? {
        do {
            let videoDescriptor = FetchDescriptor<WorkoutVideo>(sortBy: [SortDescriptor(\.order)])
            var videos = try context.fetch(videoDescriptor)

            if videos.isEmpty {
                WorkoutVideo.defaults.forEach { context.insert($0) }
                videos = try context.fetch(FetchDescriptor<WorkoutVideo>(sortBy: [SortDescriptor(\.order)]))
            } else if shouldAddMissingDefaultVideo(to: videos) {
                context.insert(WorkoutVideo.defaultVideo(order: videos.count))
                videos = try context.fetch(FetchDescriptor<WorkoutVideo>(sortBy: [SortDescriptor(\.order)]))
            }

            var settingsDescriptor = FetchDescriptor<AppSettings>()
            settingsDescriptor.fetchLimit = 1
            let settings = try context.fetch(settingsDescriptor).first ?? AppSettings()

            if settings.modelContext == nil {
                context.insert(settings)
            }

            try context.save()
            return (settings, videos.sorted { $0.order < $1.order })
        } catch {
            assertionFailure("Failed to bootstrap app data: \(error)")
            return nil
        }
    }

    private static func shouldAddMissingDefaultVideo(to videos: [WorkoutVideo]) -> Bool {
        guard videos.count == WorkoutVideo.defaultCount - 1 else {
            return false
        }

        let sortedVideos = videos.sorted { $0.order < $1.order }
        return sortedVideos.enumerated().allSatisfy { index, video in
            video.order == index
                && video.title == "動画 \(index + 1)"
                && video.youtubeURL == WorkoutVideo.placeholderURL
                && video.durationMinutes == WorkoutVideo.defaultDurationMinutes
        }
    }
}
