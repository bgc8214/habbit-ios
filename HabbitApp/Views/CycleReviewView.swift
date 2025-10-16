import SwiftUI
import SwiftData

struct CycleReviewView: View {
    let habit: Habit
    let viewModel: HabitViewModel
    let cycleNumber: Int // 보여줄 회차 번호
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 상단: 회차 정보 및 파이차트
                CycleReviewHeaderSection(
                    habit: habit,
                    viewModel: viewModel,
                    cycleNumber: cycleNumber
                )

                // 20일 달력
                if let history = viewModel.getCycleHistory(for: habit, cycle: cycleNumber) {
                    TwentyDayCalendarReviewView(
                        habit: habit,
                        viewModel: viewModel,
                        history: history
                    )
                    .padding()
                }

                // 날짜별 진행 상황
                DateProgressReviewSection(
                    habit: habit,
                    viewModel: viewModel,
                    cycleNumber: cycleNumber
                )

                // 하단: 이어가기 버튼 (현재 대기 중인 회차인 경우만)
                if habit.isWaitingForNextCycle && cycleNumber == habit.currentCycle {
                    ContinueButton(habit: habit, viewModel: viewModel, dismiss: dismiss)
                }
            }
        }
        .background(Color.black)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(habit.title) - \(cycleNumber)회차 돌아보기")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - 상단 헤더 섹션
struct CycleReviewHeaderSection: View {
    let habit: Habit
    let viewModel: HabitViewModel
    let cycleNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 회차 번호 및 날짜 범위
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(cycleNumber)회차")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    if let history = viewModel.getCycleHistory(for: habit, cycle: cycleNumber) {
                        Text(dateRangeText(history))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer()

                // 성공 여부 배지
                if let history = viewModel.getCycleHistory(for: habit, cycle: cycleNumber) {
                    VStack(spacing: 4) {
                        Text(history.isSuccessful ? "성공" : "미달성")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("\(history.completedDays)/20")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(history.isSuccessful ? Color.green.opacity(0.3) : Color.orange.opacity(0.3))
                    .cornerRadius(12)
                }
            }

            // 파이차트
            let pieData = viewModel.getPieChartData(for: habit, cycle: cycleNumber)
            PieChartView(
                miniCount: pieData.mini,
                moreCount: pieData.more,
                maxCount: pieData.max,
                skipCount: pieData.skip,
                noneCount: pieData.none
            )

            // MINI/MORE/MAX 항목 리스트
            VStack(alignment: .leading, spacing: 8) {
                LevelItemRow(level: "MINI", items: habit.miniItems, color: Color(hex: "B8E6D5"))
                LevelItemRow(level: "MORE", items: habit.moreItems, color: Color(hex: "7DB3E8"))
                LevelItemRow(level: "MAX", items: habit.maxItems, color: Color(hex: "B48FD9"))
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color(hex: habit.colorHex), Color(hex: habit.colorHex).opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func dateRangeText(_ history: CycleHistory) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M. d."
        return "\(formatter.string(from: history.startDate)) - \(formatter.string(from: history.endDate))"
    }
}

// MARK: - 20일 달력 (리뷰용)
struct TwentyDayCalendarReviewView: View {
    let habit: Habit
    let viewModel: HabitViewModel
    let history: CycleHistory

    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        VStack(spacing: 12) {
            Text("20일 달력")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<20, id: \.self) { index in
                    DayCircleReview(
                        date: dateForDay(index),
                        level: cycleRecords[index]?.level,
                        dayNumber: index + 1
                    )
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }

    private var cycleRecords: [DailyRecord?] {
        let calendar = Calendar.current
        var records: [DailyRecord?] = []

        for day in 0..<20 {
            guard let date = calendar.date(byAdding: .day, value: day, to: history.startDate) else {
                records.append(nil)
                continue
            }

            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let record = habit.records.first { record in
                record.date >= dayStart && record.date < dayEnd
            }

            records.append(record)
        }

        return records
    }

    private func dateForDay(_ index: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: index, to: history.startDate) ?? history.startDate
    }
}

// MARK: - 날짜 원 (리뷰용)
struct DayCircleReview: View {
    let date: Date
    let level: CompletionLevel?
    let dayNumber: Int

    var body: some View {
        Circle()
            .fill(backgroundColor)
            .frame(height: 60)
            .overlay(
                VStack(spacing: 2) {
                    Text("\(dayNumber)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)

                    if let level = level, level != .none {
                        Text(level.displayName)
                            .font(.system(size: 9))
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                    }
                }
            )
    }

    private var backgroundColor: Color {
        if let level = level {
            switch level {
            case .skip:
                return Color.white.opacity(0.2)
            case .mini:
                return Color(hex: "B8E6D5")
            case .more:
                return Color(hex: "7DB3E8")
            case .max:
                return Color(hex: "B48FD9")
            case .none:
                return Color.white.opacity(0.1)
            }
        }
        return Color.white.opacity(0.1)
    }

    private var textColor: Color {
        if let level = level, level == .more || level == .max {
            return .black
        }
        return .white
    }
}

// MARK: - 날짜별 진행 상황 섹션 (리뷰용)
struct DateProgressReviewSection: View {
    let habit: Habit
    let viewModel: HabitViewModel
    let cycleNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("날짜별 진행 상황")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.top, 24)

            if let history = viewModel.getCycleHistory(for: habit, cycle: cycleNumber) {
                ForEach(Array(groupedRecords(history: history).enumerated()), id: \.offset) { index, weekGroup in
                    VStack(spacing: 12) {
                        ForEach(weekGroup, id: \.date) { record in
                            DateProgressRow(record: record)
                        }
                    }
                    .padding(.vertical, 8)

                    if index < groupedRecords(history: history).count - 1 {
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.bottom, 32)
    }

    private func groupedRecords(history: CycleHistory) -> [[DailyRecord]] {
        let calendar = Calendar.current
        var allRecords: [DailyRecord] = []

        for day in 0..<20 {
            guard let date = calendar.date(byAdding: .day, value: day, to: history.startDate) else {
                continue
            }

            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            if let record = habit.records.first(where: { record in
                record.date >= dayStart && record.date < dayEnd
            }) {
                allRecords.append(record)
            } else {
                // 미완료 날짜도 표시
                let emptyRecord = DailyRecord(date: dayStart, level: .none)
                allRecords.append(emptyRecord)
            }
        }

        // 5일씩 그룹화
        var grouped: [[DailyRecord]] = []
        var currentGroup: [DailyRecord] = []

        for record in allRecords {
            currentGroup.append(record)
            if currentGroup.count == 5 {
                grouped.append(currentGroup)
                currentGroup = []
            }
        }

        if !currentGroup.isEmpty {
            grouped.append(currentGroup)
        }

        return grouped
    }
}

// MARK: - 이어가기 버튼
struct ContinueButton: View {
    let habit: Habit
    let viewModel: HabitViewModel
    let dismiss: DismissAction

    var body: some View {
        VStack(spacing: 16) {
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.horizontal)

            Button(action: {
                viewModel.startNextCycle(for: habit)
                dismiss()
            }) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("습관 이어가기")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: habit.colorHex))
                .cornerRadius(16)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    @Previewable @State var habit = Habit(
        title: "공부",
        currentCycle: 1,
        miniItems: ["클로드 코드 책 1일분"],
        moreItems: ["엘리 코딩 강의 1개", "클로드 코드 책 2일분"],
        maxItems: ["엘리 코딩 강의 2개", "클로드 코드 책 3일분"]
    )

    NavigationStack {
        CycleReviewView(
            habit: habit,
            viewModel: HabitViewModel(
                modelContext: ModelContext(
                    try! ModelContainer(for: Habit.self, DailyRecord.self, CycleHistory.self)
                )
            ),
            cycleNumber: 1
        )
    }
    .modelContainer(for: [Habit.self, DailyRecord.self, CycleHistory.self], inMemory: true)
}
