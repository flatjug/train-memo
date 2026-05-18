import Foundation
import SwiftData

@MainActor
enum AppBootstrapper {
    @discardableResult
    static func bootstrap(context: ModelContext) -> (settings: AppSettings, videos: [WorkoutVideo])? {
        do {
            var videoDescriptor = FetchDescriptor<WorkoutVideo>(sortBy: [SortDescriptor(\.order)])
            videoDescriptor.fetchLimit = 4
            var videos = try context.fetch(videoDescriptor)

            if videos.isEmpty {
                WorkoutVideo.defaults.forEach { context.insert($0) }
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
}
