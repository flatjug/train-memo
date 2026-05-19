import XCTest
@testable import TrainMemo

final class WorkoutSchedulerTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 1
    }

    func testVideoIndexUsesFourDayCycle() {
        let start = date(2026, 5, 1)

        XCTAssertEqual(WorkoutScheduler.videoIndex(for: date(2026, 5, 1), startDate: start, videoCount: 4, calendar: calendar), 0)
        XCTAssertEqual(WorkoutScheduler.videoIndex(for: date(2026, 5, 2), startDate: start, videoCount: 4, calendar: calendar), 1)
        XCTAssertEqual(WorkoutScheduler.videoIndex(for: date(2026, 5, 3), startDate: start, videoCount: 4, calendar: calendar), 2)
        XCTAssertEqual(WorkoutScheduler.videoIndex(for: date(2026, 5, 4), startDate: start, videoCount: 4, calendar: calendar), 3)
        XCTAssertEqual(WorkoutScheduler.videoIndex(for: date(2026, 5, 5), startDate: start, videoCount: 4, calendar: calendar), 0)
    }

    func testDefaultVideosUseFiveDayCycle() {
        XCTAssertEqual(WorkoutVideo.defaults.count, 5)
        XCTAssertEqual(WorkoutVideo.defaults.map(\.order), [0, 1, 2, 3, 4])
        XCTAssertTrue(WorkoutVideo.defaults.allSatisfy { $0.youtubeURL.isEmpty })
    }

    func testYouTubeURLValidationAllowsYouTubeHosts() {
        XCTAssertNotNil(WorkoutVideo.youtubeURL(from: "https://www.youtube.com/watch?v=abc"))
        XCTAssertNotNil(WorkoutVideo.youtubeURL(from: "https://youtu.be/abc"))
    }

    func testYouTubeURLValidationRejectsOtherHosts() {
        XCTAssertNil(WorkoutVideo.youtubeURL(from: "https://example.com/watch?v=abc"))
        XCTAssertNil(WorkoutVideo.youtubeURL(from: "not a url"))
    }

    func testSkippedDaysStillAdvanceByDate() {
        let start = date(2026, 5, 1)

        XCTAssertEqual(WorkoutScheduler.videoIndex(for: date(2026, 5, 7), startDate: start, videoCount: 4, calendar: calendar), 2)
    }

    func testCurrentStreakCountsBackwardFromToday() {
        let completedDays: Set<Date> = [
            date(2026, 5, 15),
            date(2026, 5, 16),
            date(2026, 5, 17)
        ]

        XCTAssertEqual(WorkoutScheduler.currentStreak(completedDays: completedDays, through: date(2026, 5, 17), calendar: calendar), 3)
    }

    func testCurrentStreakStopsAtMissingDay() {
        let completedDays: Set<Date> = [
            date(2026, 5, 15),
            date(2026, 5, 17)
        ]

        XCTAssertEqual(WorkoutScheduler.currentStreak(completedDays: completedDays, through: date(2026, 5, 17), calendar: calendar), 1)
    }

    func testTotalCompletedDaysDeduplicatesSameDayLogs() {
        let videoID = UUID()
        let logs = [
            WorkoutLog(date: date(2026, 5, 17), videoID: videoID, completedAt: dateTime(2026, 5, 17, 8, 0)),
            WorkoutLog(date: dateTime(2026, 5, 17, 21, 0), videoID: videoID, completedAt: dateTime(2026, 5, 17, 21, 0)),
            WorkoutLog(date: date(2026, 5, 18), videoID: videoID, completedAt: dateTime(2026, 5, 18, 8, 0))
        ]

        XCTAssertEqual(WorkoutScheduler.totalCompletedDays(logs: logs, calendar: calendar), 2)
    }

    func testLogsOnDateReturnsOnlyMatchingDay() {
        let videoID = UUID()
        let matchingLog = WorkoutLog(date: dateTime(2026, 5, 17, 21, 0), videoID: videoID)
        let logs = [
            WorkoutLog(date: date(2026, 5, 16), videoID: videoID),
            matchingLog,
            WorkoutLog(date: date(2026, 5, 18), videoID: videoID)
        ]

        XCTAssertEqual(WorkoutScheduler.logs(on: date(2026, 5, 17), logs: logs, calendar: calendar).map(\.id), [matchingLog.id])
    }

    func testMonthGridPadsToFullWeeks() {
        let grid = WorkoutScheduler.monthGrid(containing: date(2026, 5, 17), calendar: calendar)

        XCTAssertEqual(grid.count % 7, 0)
        XCTAssertEqual(grid.compactMap { $0 }.count, 31)
        XCTAssertNil(grid.first!)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func dateTime(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
