import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("今日", systemImage: "sun.max.fill")
                }

            HistoryView()
                .tabItem {
                    Label("記録", systemImage: "calendar")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
        }
        .tint(.mint)
        .task {
            guard let data = AppBootstrapper.bootstrap(context: modelContext) else {
                return
            }

            if data.settings.notificationEnabled {
                await NotificationScheduler.refresh(settings: data.settings, videos: data.videos)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutVideo.self, WorkoutLog.self, AppSettings.self], inMemory: true)
}
