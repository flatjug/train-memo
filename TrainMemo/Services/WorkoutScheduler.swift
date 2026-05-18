import Foundation

enum WorkoutScheduler {
    static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    static func videoIndex(
        for date: Date,
        startDate: Date,
        videoCount: Int,
        calendar: Calendar = .current
    ) -> Int? {
        guard videoCount > 0 else { return nil }

        let start = calendar.startOfDay(for: startDate)
        let target = calendar.startOfDay(for: date)
        let rawOffset = calendar.dateComponents([.day], from: start, to: target).day ?? 0
        let offset = max(0, rawOffset)

        return offset % videoCount
    }

    static func currentVideo(
        from videos: [WorkoutVideo],
        date: Date,
        settings: AppSettings,
        calendar: Calendar = .current
    ) -> WorkoutVideo? {
        let sortedVideos = videos.sorted { $0.order < $1.order }
        guard
            let index = videoIndex(
                for: date,
                startDate: settings.rotationStartDate,
                videoCount: sortedVideos.count,
                calendar: calendar
            )
        else {
            return nil
        }

        return sortedVideos[index]
    }

    static func isCompleted(
        on date: Date,
        logs: [WorkoutLog],
        calendar: Calendar = .current
    ) -> Bool {
        let target = calendar.startOfDay(for: date)
        return logs.contains { calendar.isDate($0.date, inSameDayAs: target) }
    }

    static func completedDays(from logs: [WorkoutLog], calendar: Calendar = .current) -> Set<Date> {
        Set(logs.map { calendar.startOfDay(for: $0.date) })
    }

    static func totalCompletedDays(logs: [WorkoutLog], calendar: Calendar = .current) -> Int {
        completedDays(from: logs, calendar: calendar).count
    }

    static func currentStreak(logs: [WorkoutLog], through date: Date, calendar: Calendar = .current) -> Int {
        currentStreak(completedDays: completedDays(from: logs, calendar: calendar), through: date, calendar: calendar)
    }

    static func currentStreak(completedDays: Set<Date>, through date: Date, calendar: Calendar = .current) -> Int {
        var streak = 0
        var cursor = calendar.startOfDay(for: date)

        while completedDays.contains(cursor) {
            streak += 1

            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }

            cursor = previousDay
        }

        return streak
    }

    static func monthGrid(containing date: Date, calendar: Calendar = .current) -> [Date?] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: date),
            let daysRange = calendar.range(of: .day, in: .month, for: date)
        else {
            return []
        }

        let firstDay = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leadingEmptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leadingEmptyDays)

        for day in daysRange {
            if let cellDate = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                cells.append(cellDate)
            }
        }

        while cells.count % 7 != 0 {
            cells.append(nil)
        }

        return cells
    }
}
