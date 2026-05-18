import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \WorkoutVideo.order) private var videos: [WorkoutVideo]
    @Query(sort: \WorkoutLog.date, order: .reverse) private var logs: [WorkoutLog]
    @Query private var settingsList: [AppSettings]
    @State private var errorMessage: String?

    private var settings: AppSettings? {
        settingsList.first
    }

    private var todayVideo: WorkoutVideo? {
        guard let settings else { return nil }
        return WorkoutScheduler.currentVideo(from: videos, date: Date(), settings: settings)
    }

    private var completedToday: Bool {
        WorkoutScheduler.isCompleted(on: Date(), logs: logs)
    }

    private var todayLogs: [WorkoutLog] {
        WorkoutScheduler.logs(on: Date(), logs: logs)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Date(), format: .dateTime.year().month().day().weekday(.wide))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("今日のメニュー")
                            .font(.largeTitle.bold())
                    }

                    if let video = todayVideo {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 34))
                                    .foregroundStyle(.mint)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(video.title)
                                        .font(.title2.bold())
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    Text("\(video.durationMinutes)分")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Button {
                                openVideo(video)
                            } label: {
                                Label("YouTubeを開く", systemImage: "arrow.up.forward.app.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(WorkoutVideo.youtubeURL(from: video.youtubeURL) == nil)

                            Button {
                                if completedToday {
                                    undoCompletion()
                                } else {
                                    complete(video)
                                }
                            } label: {
                                Label(completedToday ? "完了を取り消す" : "完了にする", systemImage: completedToday ? "arrow.uturn.backward.circle" : "checkmark.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                        .padding(18)
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                    } else {
                        ContentUnavailableView(
                            "動画がありません",
                            systemImage: "play.slash",
                            description: Text("設定で動画を登録してください")
                        )
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Spacer(minLength: 0)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("筋トレメモ")
        }
    }

    private func openVideo(_ video: WorkoutVideo) {
        guard let url = WorkoutVideo.youtubeURL(from: video.youtubeURL) else {
            errorMessage = "YouTube URLが正しくありません"
            return
        }

        errorMessage = nil
        openURL(url)
    }

    private func complete(_ video: WorkoutVideo) {
        guard !completedToday else { return }

        let today = Calendar.current.startOfDay(for: Date())
        modelContext.insert(WorkoutLog(date: today, videoID: video.id))

        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "完了記録の保存に失敗しました"
        }
    }

    private func undoCompletion() {
        let logsToDelete = todayLogs
        guard !logsToDelete.isEmpty else { return }

        logsToDelete.forEach { modelContext.delete($0) }

        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "完了記録の取り消しに失敗しました"
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [WorkoutVideo.self, WorkoutLog.self, AppSettings.self], inMemory: true)
}
