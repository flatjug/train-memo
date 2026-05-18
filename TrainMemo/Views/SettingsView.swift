import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutVideo.order) private var videos: [WorkoutVideo]
    @Query private var settingsList: [AppSettings]
    @State private var notificationMessage: String?

    private let durationRange = 1...180

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

                Section("ローテーション") {
                    if let settings {
                        DatePicker(
                            "開始日",
                            selection: rotationStartDateBinding(for: settings),
                            displayedComponents: .date
                        )
                    } else {
                        Text("設定を準備中です")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("動画") {
                    let sortedVideos = videos.sorted { $0.order < $1.order }

                    ForEach(Array(sortedVideos.enumerated()), id: \.element.id) { index, video in
                        VideoEditorRow(
                            video: video,
                            displayIndex: index + 1,
                            canMoveUp: index > 0,
                            canMoveDown: index < videos.count - 1,
                            canDelete: videos.count > 1,
                            durationRange: durationRange,
                            moveUp: { moveVideo(video, by: -1) },
                            moveDown: { moveVideo(video, by: 1) },
                            delete: { deleteVideo(video) }
                        )
                    }

                    Button {
                        addVideo()
                    } label: {
                        Label("動画を追加", systemImage: "plus.circle.fill")
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
            settings.notificationHour = components.hour ?? AppSettings.defaultNotificationHour
            settings.notificationMinute = components.minute ?? AppSettings.defaultNotificationMinute
            saveAndScheduleNotifications()
        }
    }

    private func rotationStartDateBinding(for settings: AppSettings) -> Binding<Date> {
        Binding {
            settings.rotationStartDate
        } set: { newDate in
            settings.rotationStartDate = Calendar.current.startOfDay(for: newDate)
            saveAndScheduleNotifications()
        }
    }

    private func addVideo() {
        let nextOrder = (videos.map(\.order).max() ?? -1) + 1
        let video = WorkoutVideo(
            order: nextOrder,
            title: "動画 \(videos.count + 1)",
            youtubeURL: WorkoutVideo.placeholderURL,
            durationMinutes: WorkoutVideo.defaultDurationMinutes
        )

        modelContext.insert(video)
        saveAndScheduleNotifications()
    }

    private func deleteVideo(_ video: WorkoutVideo) {
        guard videos.count > 1 else { return }

        modelContext.delete(video)
        normalizeVideoOrder(excluding: video.id)
        saveAndScheduleNotifications()
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

    private func normalizeVideoOrder(excluding deletedVideoID: UUID? = nil) {
        let sortedVideos = videos
            .filter { $0.id != deletedVideoID }
            .sorted { $0.order < $1.order }

        for (index, video) in sortedVideos.enumerated() {
            video.order = index
        }
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
    let canDelete: Bool
    let durationRange: ClosedRange<Int>
    let moveUp: () -> Void
    let moveDown: () -> Void
    let delete: () -> Void

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

                Button(role: .destructive, action: delete) {
                    Image(systemName: "trash")
                }
                .disabled(!canDelete)
            }

            TextField("タイトル", text: $video.title)
                .textInputAutocapitalization(.never)

            TextField("YouTube URL", text: $video.youtubeURL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Stepper(value: $video.durationMinutes, in: durationRange) {
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
