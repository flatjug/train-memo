import Foundation
import UserNotifications

@MainActor
enum NotificationScheduler {
    enum ScheduleResult {
        case disabled
        case denied
        case scheduled(Int)
        case failed(String)

        var message: String {
            switch self {
            case .disabled:
                return "通知はオフです"
            case .denied:
                return "通知が許可されていません"
            case .scheduled(let count):
                return "\(count)日分の通知を更新しました"
            case .failed(let message):
                return message
            }
        }
    }

    private static let identifierPrefix = "daily-workout"
    private static let scheduleDays = 32

    @discardableResult
    static func refresh(
        settings: AppSettings,
        videos: [WorkoutVideo],
        calendar: Calendar = .current,
        now: Date = Date()
    ) async -> ScheduleResult {
        let center = UNUserNotificationCenter.current()
        await removePendingWorkoutNotifications(center: center)

        guard settings.notificationEnabled else {
            return .disabled
        }

        let sortedVideos = videos.sorted { $0.order < $1.order }
        guard !sortedVideos.isEmpty else {
            return .failed("通知に使う動画がありません")
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else {
                return .denied
            }

            var scheduledCount = 0
            var dayOffset = 0
            let today = calendar.startOfDay(for: now)

            while scheduledCount < scheduleDays {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                    break
                }

                dayOffset += 1
                guard
                    let fireDate = calendar.date(
                        bySettingHour: settings.notificationHour,
                        minute: settings.notificationMinute,
                        second: 0,
                        of: day
                    ),
                    fireDate > now,
                    let index = WorkoutScheduler.videoIndex(
                        for: day,
                        startDate: settings.rotationStartDate,
                        videoCount: sortedVideos.count,
                        calendar: calendar
                    )
                else {
                    continue
                }

                let video = sortedVideos[index]
                let content = UNMutableNotificationContent()
                content.title = "今日の筋トレ"
                content.body = "\(video.title)をやる日です"
                content.sound = .default
                content.userInfo = ["videoID": video.id.uuidString]

                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: notificationIdentifier(for: day, calendar: calendar),
                    content: content,
                    trigger: trigger
                )

                try await center.add(request)
                scheduledCount += 1
            }

            return .scheduled(scheduledCount)
        } catch {
            return .failed("通知の更新に失敗しました")
        }
    }

    private static func removePendingWorkoutNotifications(center: UNUserNotificationCenter) async {
        let pendingRequests = await center.pendingNotificationRequests()
        let identifiers = pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func notificationIdentifier(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return [
            identifierPrefix,
            components.year.map(String.init) ?? "0000",
            components.month.map(String.init) ?? "00",
            components.day.map(String.init) ?? "00"
        ].joined(separator: ".")
    }
}
