import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutVideo.order) private var videos: [WorkoutVideo]
    @Query private var settingsList: [AppSettings]
    @State private var notificationMessage: String?

    private var settings: AppSettings? {
        settingsList.first
    }

    private var videoSignature: String {
        videos
            .sorted { $0.order < $1.order }
            .map { "\($0.id.uuidString)|\($0.order)|\($0.title)|\($0.youtubeURL)|\($0.durationMinutes)" }
            .joined(separator: "#")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("通知") {
                    if let settings {
                        Toggle(
                            "毎日通知する",
                            isOn: Binding(
                                get: { settings.notificationEnabled },
                                set: { newValue in
                                    settings.notificationEnabled = newValue
                                    saveAndScheduleNotifications()
                                }
                            )
                        )

                        DatePicker(
                            "通知時刻",
                            selection: notificationDateBinding(for: settings),
                            displayedComponents: .hourAndMinute
                        )
                        .disabled(!settings.notificationEnabled)

                        if let notificationMessage {
                            Text(notificationMessage)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("設定を準備中です")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("動画") {
                    ForEach(Array(videos.sorted { $0.order < $1.order }.enumerated()), id: \.element.id) { index, video in
                        VideoEditorRow(
                            video: video,
                            displayIndex: index + 1,
                            canMoveUp: index > 0,
                            canMoveDown: index < videos.count - 1,
                            moveUp: { moveVideo(video, by: -1) },
                            moveDown: { moveVideo(video, by: 1) }
                        )
                    }
                }
            }
            .navigationTitle("設定")
            .onChange(of: videoSignature) {
                saveAndScheduleNotifications()
            }
        }
    }

    private func notificationDateBinding(for settings: AppSettings) -> Binding<Date> {
        Binding {
            Calendar.current.date(
                bySettingHour: settings.notificationHour,
                minute: settings.notificationMinute,
                second: 0,
                of: Date()
            ) ?? Date()
        } set: { newDate in
            let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
            settings.notificationHour = components.hour ?? 20
            settings.notificationMinute = components.minute ?? 0
            saveAndScheduleNotifications()
        }
    }

    private func moveVideo(_ video: WorkoutVideo, by offset: Int) {
        let sortedVideos = videos.sorted { $0.order < $1.order }
        guard
            let currentIndex = sortedVideos.firstIndex(where: { $0.id == video.id }),
            sortedVideos.indices.contains(currentIndex + offset)
        else {
            return
        }

        let otherVideo = sortedVideos[currentIndex + offset]
        let oldOrder = video.order
        video.order = otherVideo.order
        otherVideo.order = oldOrder
        saveAndScheduleNotifications()
    }

    private func saveAndScheduleNotifications() {
        do {
            try modelContext.save()
        } catch {
            notificationMessage = "設定の保存に失敗しました"
            return
        }

        guard let settings else { return }

        Task { @MainActor in
            let result = await NotificationScheduler.refresh(settings: settings, videos: videos)
            if case .denied = result {
                settings.notificationEnabled = false
                try? modelContext.save()
            }
            notificationMessage = result.message
        }
    }
}

private struct VideoEditorRow: View {
    @Bindable var video: WorkoutVideo
    let displayIndex: Int
    let canMoveUp: Bool
    let canMoveDown: Bool
    let moveUp: () -> Void
    let moveDown: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("動画 \(displayIndex)")
                    .font(.headline)

                Spacer()

                Button(action: moveUp) {
                    Image(systemName: "chevron.up")
                }
                .disabled(!canMoveUp)

                Button(action: moveDown) {
                    Image(systemName: "chevron.down")
                }
                .disabled(!canMoveDown)
            }

            TextField("タイトル", text: $video.title)
                .textInputAutocapitalization(.never)

            TextField("YouTube URL", text: $video.youtubeURL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Stepper(value: $video.durationMinutes, in: 1...180) {
                Text("\(video.durationMinutes)分")
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [WorkoutVideo.self, WorkoutLog.self, AppSettings.self], inMemory: true)
}
