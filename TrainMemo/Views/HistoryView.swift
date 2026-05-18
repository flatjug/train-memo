import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \WorkoutLog.date, order: .reverse) private var logs: [WorkoutLog]
    @State private var displayedMonth = Date()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekdaySymbols = Calendar.current.shortStandaloneWeekdaySymbols

    private var completedDays: Set<Date> {
        WorkoutScheduler.completedDays(from: logs)
    }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.year().month(.wide))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        StatView(title: "連続", value: "\(WorkoutScheduler.currentStreak(logs: logs, through: Date()))日")
                        StatView(title: "合計", value: "\(WorkoutScheduler.totalCompletedDays(logs: logs))日")
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(monthTitle)
                                .font(.title2.bold())

                            Spacer()

                            Button {
                                moveMonth(by: -1)
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                            .buttonStyle(.bordered)

                            Button {
                                moveMonth(by: 1)
                            } label: {
                                Image(systemName: "chevron.right")
                            }
                            .buttonStyle(.bordered)
                        }

                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(weekdaySymbols, id: \.self) { symbol in
                                Text(symbol)
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                            }

                            ForEach(Array(WorkoutScheduler.monthGrid(containing: displayedMonth).enumerated()), id: \.offset) { _, date in
                                CalendarDayCell(date: date, isCompleted: isCompleted(date), isToday: isToday(date))
                            }
                        }
                    }
                    .padding(16)
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("記録")
        }
    }

    private func isCompleted(_ date: Date?) -> Bool {
        guard let date else { return false }
        return completedDays.contains(Calendar.current.startOfDay(for: date))
    }

    private func isToday(_ date: Date?) -> Bool {
        guard let date else { return false }
        return Calendar.current.isDateInToday(date)
    }

    private func moveMonth(by value: Int) {
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) else {
            return
        }

        displayedMonth = nextMonth
    }
}

private struct StatView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title.bold())
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct CalendarDayCell: View {
    let date: Date?
    let isCompleted: Bool
    let isToday: Bool

    var body: some View {
        ZStack {
            if let date {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCompleted ? Color.mint.opacity(0.9) : Color(.secondarySystemGroupedBackground))
                    .overlay {
                        if isToday {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.mint, lineWidth: 2)
                        }
                    }

                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.callout.weight(isCompleted ? .bold : .regular))
                    .foregroundStyle(isCompleted ? .white : .primary)
            }
        }
        .frame(height: 44)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [WorkoutVideo.self, WorkoutLog.self, AppSettings.self], inMemory: true)
}
