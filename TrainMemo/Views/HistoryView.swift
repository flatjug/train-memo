import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutLog.date, order: .reverse) private var logs: [WorkoutLog]
    @Query(sort: \WorkoutVideo.order) private var videos: [WorkoutVideo]
    @State private var displayedMonth = Date()
    @State private var selectedDate: Date?
    @State private var errorMessage: String?

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
                                CalendarDayCell(
                                    date: date,
                                    isCompleted: isCompleted(date),
                                    isToday: isToday(date),
                                    select: { selectDate(date) }
                                )
                            }
                        }
                    }
                    .padding(16)
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("記録")
            .sheet(item: selectedDayDetailBinding) { detail in
                DayDetailView(
                    detail: detail,
                    deleteLogs: { deleteLogs(on: detail.date) }
                )
                .presentationDetents([.medium])
            }
        }
    }

    private var selectedDayDetailBinding: Binding<DayDetail?> {
        Binding {
            guard let selectedDate else { return nil }
            return dayDetail(for: selectedDate)
        } set: { detail in
            selectedDate = detail?.date
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

    private func selectDate(_ date: Date?) {
        guard let date else { return }
        selectedDate = Calendar.current.startOfDay(for: date)
        errorMessage = nil
    }

    private func dayDetail(for date: Date) -> DayDetail {
        let logsForDay = WorkoutScheduler.logs(on: date, logs: logs)
        return DayDetail(
            date: Calendar.current.startOfDay(for: date),
            items: logsForDay.map { log in
                DayDetail.Item(
                    id: log.id,
                    videoTitle: videoTitle(for: log.videoID),
                    completedAt: log.completedAt
                )
            }
        )
    }

    private func videoTitle(for videoID: UUID) -> String {
        videos.first { $0.id == videoID }?.title ?? "削除済みの動画"
    }

    private func deleteLogs(on date: Date) {
        let logsToDelete = WorkoutScheduler.logs(on: date, logs: logs)
        guard !logsToDelete.isEmpty else { return }

        logsToDelete.forEach { modelContext.delete($0) }

        do {
            try modelContext.save()
            selectedDate = nil
            errorMessage = nil
        } catch {
            errorMessage = "記録の取り消しに失敗しました"
        }
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
    let select: () -> Void

    var body: some View {
        Button(action: select) {
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
        }
        .frame(height: 44)
        .buttonStyle(.plain)
        .disabled(date == nil)
    }
}

private struct DayDetail: Identifiable {
    struct Item: Identifiable {
        let id: UUID
        let videoTitle: String
        let completedAt: Date
    }

    let date: Date
    let items: [Item]

    var id: Date {
        date
    }
}

private struct DayDetailView: View {
    let detail: DayDetail
    let deleteLogs: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if detail.items.isEmpty {
                        Text("この日の記録はありません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(detail.items) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.videoTitle)
                                    .font(.headline)
                                Text(item.completedAt, format: .dateTime.hour().minute())
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if !detail.items.isEmpty {
                    Section {
                        Button(role: .destructive, action: deleteLogs) {
                            Label("この日の記録を取り消す", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(detail.date.formatted(.dateTime.month().day().weekday(.wide)))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [WorkoutVideo.self, WorkoutLog.self, AppSettings.self], inMemory: true)
}
