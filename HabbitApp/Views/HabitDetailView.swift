import SwiftUI
import SwiftData

enum StatTab: String, CaseIterable {
    case currentCycle = "이번 회차"
    case allStats = "전체 통계"
    case previousCycles = "이전 회차"
}

struct HabitDetailView: View {
    let habit: Habit
    let viewModel: HabitViewModel
    @State private var selectedTab: StatTab = .currentCycle
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 탭 바 (항상 표시)
            StatTabBar(selectedTab: $selectedTab, habit: habit)

            // 탭별 콘텐츠
            ScrollView {
                VStack(spacing: 0) {
                    switch selectedTab {
                    case .currentCycle:
                        CurrentCycleView(habit: habit, viewModel: viewModel)
                    case .allStats:
                        AllStatsView(habit: habit, viewModel: viewModel)
                    case .previousCycles:
                        PreviousCyclesView(habit: habit, viewModel: viewModel)
                    }
                }
            }
        }
        .background(Color.black)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .alert("습관 삭제", isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                viewModel.deleteHabit(habit)
                dismiss()
            }
        } message: {
            Text("'\(habit.title)' 습관을 삭제하시겠습니까?\n\n삭제된 습관은 복구할 수 없습니다.")
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(habit.title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    NavigationLink(destination: EditHabitView(habit: habit, viewModel: viewModel)) {
                        Text("수정")
                            .foregroundColor(.white)
                    }
                    
                    Button("삭제") {
                        showingDeleteAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - 현재 회차 뷰
struct CurrentCycleView: View {
    let habit: Habit
    let viewModel: HabitViewModel

    var body: some View {
        VStack(spacing: 0) {
            // 상단: 습관 정보 및 통계
            HabitDetailHeaderSection(habit: habit, viewModel: viewModel)

            // 날짜별 진행 상황
            DateProgressSection(habit: habit, viewModel: viewModel)
        }
    }
}

// MARK: - 상단 헤더 섹션
struct HabitDetailHeaderSection: View {
    let habit: Habit
    let viewModel: HabitViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 날짜 범위 및 DAY
            HStack {
                Text(dateRangeText)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("DAY")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(viewModel.getCurrentCycleDay(for: habit))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }

            // 습관 제목
            Text(habit.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // MINI/MORE/MAX 항목 리스트
            VStack(alignment: .leading, spacing: 8) {
                LevelItemRow(level: "MINI", items: habit.miniItems, color: Color(hex: "B8E6D5"))
                LevelItemRow(level: "MORE", items: habit.moreItems, color: Color(hex: "7DB3E8"))
                LevelItemRow(level: "MAX", items: habit.maxItems, color: Color(hex: "B48FD9"))
            }

            // 20일 달력 그리드
            TwentyDayCalendarView(habit: habit, viewModel: viewModel)

            // 하단 통계
            HStack(spacing: 32) {
                StatBox(label: "최초시작", value: formatDate(habit.startDate))
                StatBox(label: "총회차", value: "\(habit.currentCycle)")
                StatBox(label: "총실천", value: "\(habit.records.count)")
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

    private var dateRangeText: String {
        let startDate = viewModel.getCurrentCycleStartDate(for: habit)
        let endDate = viewModel.getCurrentCycleEndDate(for: habit)

        let formatter = DateFormatter()
        formatter.dateFormat = "M. d."

        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy. M. d."
        return formatter.string(from: date)
    }
}

// MARK: - 레벨 항목 행
struct LevelItemRow: View {
    let level: String
    let items: [String]
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(level)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(items.joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - 20일 달력 뷰
struct TwentyDayCalendarView: View {
    let habit: Habit
    let viewModel: HabitViewModel

    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<20, id: \.self) { index in
                    DayCircle(
                        date: dateForDay(index),
                        level: cycleRecords[index]?.level,
                        isToday: index + 1 == currentDay
                    )
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }

    private var cycleRecords: [DailyRecord?] {
        viewModel.getCurrentCycleRecords(for: habit)
    }

    private var currentDay: Int {
        viewModel.getCurrentCycleDay(for: habit)
    }

    private func dateForDay(_ index: Int) -> Date {
        let startDate = viewModel.getCurrentCycleStartDate(for: habit)
        return Calendar.current.date(byAdding: .day, value: index, to: startDate) ?? startDate
    }
}

// MARK: - 날짜 원 (20일 달력용)
struct DayCircle: View {
    let date: Date
    let level: CompletionLevel?
    let isToday: Bool

    var body: some View {
        Circle()
            .fill(backgroundColor)
            .frame(height: 60)
            .overlay(
                VStack(spacing: 2) {
                    Text(formatDate(date))
                        .font(.caption2)
                        .foregroundColor(textColor)

                    if let level = level, level != .none {
                        Text(level.displayName)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                    }
                }
            )
            .overlay(
                Circle()
                    .strokeBorder(isToday ? Color.white : Color.clear, lineWidth: 3)
            )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d(E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    private var backgroundColor: Color {
        if let level = level {
            switch level {
            case .skip:
                return Color.white.opacity(0.2)
            case .mini:
                return Color.white.opacity(0.4)
            case .more:
                return Color.white.opacity(0.6)
            case .max:
                return Color.white.opacity(0.9)
            case .none:
                return Color.white.opacity(0.1)
            }
        }
        return Color.white.opacity(0.1)
    }

    private var textColor: Color {
        if let level = level, level == .max || level == .more {
            return .black
        }
        return .white
    }
}

// MARK: - 통계 박스
struct StatBox: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

// MARK: - 날짜별 진행 상황 섹션
struct DateProgressSection: View {
    let habit: Habit
    let viewModel: HabitViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("날짜별 진행 상황")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.top, 24)

            ForEach(Array(groupedRecords.enumerated()), id: \.offset) { index, weekGroup in
                VStack(spacing: 12) {
                    ForEach(weekGroup, id: \.date) { record in
                        DateProgressRow(record: record)
                    }
                }
                .padding(.vertical, 8)

                if index < groupedRecords.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 32)
    }

    private var groupedRecords: [[DailyRecord]] {
        let cycleRecords = viewModel.getCurrentCycleRecords(for: habit)
        let calendar = Calendar.current
        let startDate = viewModel.getCurrentCycleStartDate(for: habit)

        var allRecords: [DailyRecord] = []

        for (index, record) in cycleRecords.enumerated() {
            if let record = record {
                allRecords.append(record)
            } else {
                // 미완료 날짜도 표시하기 위해 빈 레코드 생성
                if let date = calendar.date(byAdding: .day, value: index, to: startDate) {
                    let emptyRecord = DailyRecord(date: date, level: .none)
                    allRecords.append(emptyRecord)
                }
            }
        }

        // 오래된 날짜부터 정렬 (시작일부터 최근까지)
        allRecords.sort { $0.date < $1.date }

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

// MARK: - 날짜별 진행 행
struct DateProgressRow: View {
    let record: DailyRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 한 줄로: 날짜 - 레벨 - 항목 - 메모
            HStack(alignment: .top, spacing: 12) {
                // 날짜
                Text(formatDate(record.date))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 90, alignment: .leading)

                // 레벨 표시
                Text(record.level.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(levelColor)
                    .frame(width: 50, alignment: .leading)

                // 완료한 항목들 + 메모
                VStack(alignment: .leading, spacing: 4) {
                    if !record.selectedItems.isEmpty {
                        Text(record.selectedItems.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    if let memo = record.memo, !memo.isEmpty {
                        Text(memo)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d(E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    private var levelColor: Color {
        switch record.level {
        case .skip:
            return .gray
        case .mini:
            return Color(hex: "B8E6D5")
        case .more:
            return Color(hex: "7DB3E8")
        case .max:
            return Color(hex: "B48FD9")
        case .none:
            return .clear
        }
    }
}

#Preview {
    @Previewable @State var habit = Habit(
        title: "공부",
        miniItems: ["클로드 코드 책 1일분"],
        moreItems: ["엘리 코딩 강의 1개", "클로드 코드 책 2일분"],
        maxItems: ["엘리 코딩 강의 2개", "클로드 코드 책 3일분"]
    )

    NavigationStack {
        HabitDetailView(
            habit: habit,
            viewModel: HabitViewModel(
                modelContext: ModelContext(
                    try! ModelContainer(for: Habit.self, DailyRecord.self, CycleHistory.self)
                )
            )
        )
    }
    .modelContainer(for: [Habit.self, DailyRecord.self, CycleHistory.self], inMemory: true)
}

// MARK: - 통계 탭 바
struct StatTabBar: View {
    @Binding var selectedTab: StatTab
    let habit: Habit

    var body: some View {
        HStack(spacing: 0) {
            ForEach(availableTabs, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    Text(tab.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedTab == tab ? .semibold : .regular)
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == tab ? Color.white.opacity(0.1) : Color.clear)
                }
            }
        }
        .background(Color.black)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.white.opacity(0.2)),
            alignment: .bottom
        )
    }

    private var availableTabs: [StatTab] {
        // 이전 회차가 있으면 모든 탭 표시, 없으면 "이전 회차" 탭만 제외
        if habit.cycleHistories.count > 0 {
            return StatTab.allCases
        } else {
            return [.currentCycle, .allStats]
        }
    }
}

// MARK: - 전체 통계 뷰
struct AllStatsView: View {
    let habit: Habit
    let viewModel: HabitViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 전체 통계 헤더
            AllStatsHeaderSection(habit: habit, viewModel: viewModel)

            // 파이차트 (전체 통합 데이터)
            let stats = viewModel.getAllCyclesStats(for: habit)
            PieChartView(
                miniCount: stats.miniCount,
                moreCount: stats.moreCount,
                maxCount: stats.maxCount,
                skipCount: stats.skipCount,
                noneCount: stats.totalDays - stats.completedDays
            )
            .padding()

            // 통계 요약
            AllStatsSummary(habit: habit, viewModel: viewModel)
        }
        .padding(.bottom, 32)
    }
}

// MARK: - 전체 통계 헤더
struct AllStatsHeaderSection: View {
    let habit: Habit
    let viewModel: HabitViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("전체 습관 통계")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            let stats = viewModel.getAllCyclesStats(for: habit)

            HStack(spacing: 32) {
                StatBox(label: "총 회차", value: "\(habit.currentCycle)")
                StatBox(label: "성공 회차", value: "\(stats.successfulCycles)")
                StatBox(label: "총 실천일", value: "\(stats.completedDays)")
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
}

// MARK: - 전체 통계 요약
struct AllStatsSummary: View {
    let habit: Habit
    let viewModel: HabitViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("상세 통계")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            let stats = viewModel.getAllCyclesStats(for: habit)

            VStack(spacing: 16) {
                StatsRow(label: "MINI 완료", value: "\(stats.miniCount)일", color: Color(hex: "B8E6D5"))
                StatsRow(label: "MORE 완료", value: "\(stats.moreCount)일", color: Color(hex: "7DB3E8"))
                StatsRow(label: "MAX 완료", value: "\(stats.maxCount)일", color: Color(hex: "B48FD9"))
                StatsRow(label: "SKIP", value: "\(stats.skipCount)일", color: Color.gray.opacity(0.5))

                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.vertical, 8)

                StatsRow(
                    label: "전체 완료율",
                    value: "\(Int(Double(stats.completedDays) / Double(stats.totalDays) * 100))%",
                    color: Color.white
                )
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}

// MARK: - 통계 행
struct StatsRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

// MARK: - 이전 회차 뷰
struct PreviousCyclesView: View {
    let habit: Habit
    let viewModel: HabitViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("이전 회차")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()

            if habit.cycleHistories.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.5))

                    Text("아직 완료된 회차가 없습니다")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 80)
            } else {
                ForEach(habit.cycleHistories.sorted(by: { $0.cycleNumber > $1.cycleNumber }), id: \.id) { history in
                    NavigationLink(destination: CycleReviewView(habit: habit, viewModel: viewModel, cycleNumber: history.cycleNumber)) {
                        PreviousCycleCard(history: history, habitColor: Color(hex: habit.colorHex))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 32)
    }
}

// MARK: - 이전 회차 카드
struct PreviousCycleCard: View {
    let history: CycleHistory
    let habitColor: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(history.cycleNumber)회차")
                    .font(.headline)
                    .foregroundColor(.white)

                Text(dateRangeText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text("MINI")
                            .font(.caption2)
                        Text("\(history.miniCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white.opacity(0.8))

                    HStack(spacing: 4) {
                        Text("MORE")
                            .font(.caption2)
                        Text("\(history.moreCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white.opacity(0.8))

                    HStack(spacing: 4) {
                        Text("MAX")
                            .font(.caption2)
                        Text("\(history.maxCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: history.isSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(history.isSuccessful ? .green : .orange)
                    .font(.title2)

                Text("\(history.completedDays)/20")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(history.isSuccessful ? "성공" : "미달성")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [habitColor.opacity(0.3), habitColor.opacity(0.2)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
    }

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M. d."
        return "\(formatter.string(from: history.startDate)) - \(formatter.string(from: history.endDate))"
    }
}
