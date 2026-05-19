import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = AppTab.today

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("今日", systemImage: "sun.max.fill")
                }
                .tag(AppTab.today)

            HistoryView()
                .tabItem {
                    Label("記録", systemImage: "calendar")
                }
                .tag(AppTab.history)

            SettingsView {
                selectedTab = .today
            }
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
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

private enum AppTab {
    case today
    case history
    case settings
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutVideo.self, WorkoutLog.self, AppSettings.self], inMemory: true)
}
