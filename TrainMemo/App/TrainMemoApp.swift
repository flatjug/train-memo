import SwiftData
import SwiftUI

@main
struct TrainMemoApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: WorkoutVideo.self, WorkoutLog.self, AppSettings.self)
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
