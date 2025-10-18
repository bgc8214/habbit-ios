import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HabitViewModel?
    @State private var showAddHabit = false
    @State private var refreshTrigger = 0 // UI 새로고침 트리거
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if let viewModel = viewModel {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 응원 메시지
                            VStack(spacing: 8) {
                                Text("응원해요, 백규철님!")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                Text("오늘도 실천을 향해 한 걸음씩!")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                            .padding(.bottom, 10)

                            // 습관 카드들
                            if viewModel.habits.isEmpty {
                                EmptyStateView(onAddTapped: { showAddHabit = true })
                            } else {
                                ForEach(viewModel.habits) { habit in
                                    HabitCardView(
                                        habit: habit,
                                        viewModel: viewModel
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                } else {
                    ProgressView()
                        .tint(.white)
                }
                
                // 하단 추가 버튼
                VStack {
                    Spacer()
                    
                    Button(action: { showAddHabit = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("새 습관 추가하기")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showAddHabit, onDismiss: {
                // sheet가 닫힐 때 습관 목록 새로고침
                print("🔄 AddHabitView 닫힘 - 습관 목록 새로고침")
                viewModel?.fetchHabits()
                refreshTrigger += 1 // UI 강제 새로고침
                print("✅ 습관 목록 새로고침 완료, 현재 습관 수: \(viewModel?.habits.count ?? 0)")
            }) {
                if let viewModel = viewModel {
                    AddHabitView(viewModel: viewModel)
                }
            }
            .id(refreshTrigger) // refreshTrigger가 변경되면 뷰 재생성
        }
        .onAppear {
            print("🔄 HomeView onAppear")
            if viewModel == nil {
                print("🔄 HabitViewModel 초기화")
                viewModel = HabitViewModel(modelContext: modelContext)
            } else {
                // 화면이 나타날 때마다 새로고침
                print("🔄 기존 ViewModel로 습관 목록 새로고침")
                viewModel?.fetchHabits()
                print("✅ 습관 목록 새로고침 완료, 현재 습관 수: \(viewModel?.habits.count ?? 0)")
            }
        }
    }
}

// MARK: - 전체 통계 헤더
struct GlobalStatsHeader: View {
    let viewModel: HabitViewModel
    
    var body: some View {
        HStack {
            // 왼쪽: 아이콘과 총 습관 수
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("\(viewModel.habits.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // 오른쪽: 통계 정보들
            HStack(spacing: 16) {
                StatItem(icon: "folder.fill", text: "총회차 1")
                StatItem(icon: "hand.clap.fill", text: "총실천 \(totalCompletedDays)")
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    private var totalCompletedDays: Int {
        viewModel.habits.reduce(0) { total, habit in
            total + habit.records.count
        }
    }
}

struct StatItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - 새로운 습관 카드
struct HabitCardView: View {
    let habit: Habit
    let viewModel: HabitViewModel

    var body: some View {
        // 대기 상태인 경우 CycleReviewView로 이동
        if habit.isWaitingForNextCycle {
            HabitCardWaitingView(habit: habit, viewModel: viewModel)
        } else {
            HabitCardActiveView(habit: habit, viewModel: viewModel)
        }
    }
}

// MARK: - 대기 상태 카드
struct HabitCardWaitingView: View {
    let habit: Habit
    let viewModel: HabitViewModel

    var body: some View {
        NavigationLink(destination: CycleReviewView(habit: habit, viewModel: viewModel, cycleNumber: habit.currentCycle)) {
            VStack(spacing: 0) {
                // 상단 통계 바
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)

                    Text("\(habit.currentCycle)회차 완료")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle")
                            .foregroundColor(.white.opacity(0.7))
                        Text("돌아보기")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))

                // 메인 카드 영역
                VStack(alignment: .center, spacing: 20) {
                    Spacer()

                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.8))

                    VStack(spacing: 8) {
                        Text("\(habit.title)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("\(habit.currentCycle)회차를 완료했어요!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        Text("탭하여 돌아보고 다음 회차를 시작하세요")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 4)
                    }

                    Spacer()
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color(hex: habit.colorHex).opacity(0.6), Color(hex: habit.colorHex).opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 활성 상태 카드
struct HabitCardActiveView: View {
    let habit: Habit
    let viewModel: HabitViewModel

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // 전체 카드 영역 - 상세 페이지로 이동
            NavigationLink(destination: HabitDetailView(habit: habit, viewModel: viewModel)) {
                VStack(spacing: 0) {
                    // 상단 통계 바
                    HStack {
                        Text(habit.emoji)
                            .font(.title)

                        Text("\(habit.records.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Spacer()

                        HStack(spacing: 16) {
                            StatItem(icon: "folder.fill", text: "총회차 \(habit.currentCycle)")
                            StatItem(icon: "hand.clap.fill", text: "총실천 \(habit.records.count)")
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))

                    // 메인 카드 영역
                    VStack(alignment: .leading, spacing: 16) {
                        // 제목과 시작일
                        HStack {
                            Text(habit.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Spacer()

                            Text(formatStartDate(habit.startDate))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        // 20일 진행도 점들
                        ProgressDotsView(habit: habit, viewModel: viewModel)

                        // MINI/MORE/MAX 횟수 텍스트
                        HStack(spacing: 32) {
                            LevelCountText(level: "MINI", count: miniCount)
                            LevelCountText(level: "MORE", count: moreCount)
                            LevelCountText(level: "MAX", count: maxCount)
                        }

                        // SKIP 날짜들 표시
                        HStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Text("12일 (월)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("13일 (월)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))

                                // TODAY 버튼을 위한 공간 확보
                                Spacer()
                                    .frame(width: 50, height: 50)
                            }
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [habitColor, habitColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // TODAY 버튼 - 체크 페이지로 이동 (상위 레이어)
            NavigationLink(destination: HabitCheckView(habit: habit, viewModel: viewModel)) {
                ZStack {
                    Circle()
                        .fill(todayButtonColor)
                        .frame(width: 50, height: 50)

                    if isTodayCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("TODAY")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(habitColor)
                    }
                }
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 16)
            .padding(.bottom, 16)
        }
    }
    
    private var habitColor: Color {
        Color(hex: habit.colorHex)
    }

    private var isTodayCompleted: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return habit.records.contains { record in
            calendar.isDate(record.date, inSameDayAs: today) && record.level != .none
        }
    }

    private var todayButtonColor: Color {
        if isTodayCompleted {
            return habitColor // 완료 시 습관 색상
        } else {
            return .white // 미완료 시 흰색
        }
    }

    private func formatStartDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy. M. d."
        return formatter.string(from: date) + "~"
    }
    
    private var miniCount: Int {
        habit.records.filter { $0.level == .mini }.count
    }
    
    private var moreCount: Int {
        habit.records.filter { $0.level == .more }.count
    }
    
    private var maxCount: Int {
        habit.records.filter { $0.level == .max }.count
    }
}

// MARK: - 레벨별 횟수 텍스트
struct LevelCountText: View {
    let level: String
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(level)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.8))
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}

// MARK: - 진행도 점들
struct ProgressDotsView: View {
    let habit: Habit
    let viewModel: HabitViewModel

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: 12, height: 12)
            }
        }
    }
    
    private func dotColor(for index: Int) -> Color {
        // 현재 사이클의 기록 가져오기
        let cycleRecords = viewModel.getCurrentCycleRecords(for: habit)

        guard index < cycleRecords.count else {
            return .white.opacity(0.1)
        }

        let record = cycleRecords[index]
        let currentDay = viewModel.getCurrentCycleDay(for: habit)

        // 기록이 있으면 레벨에 따라 색상 표시 (오늘 날짜 체크보다 우선)
        if let level = record?.level, level != .none {
            switch level {
            case .skip:
                return .white.opacity(0.1)
            case .mini:
                return .white.opacity(0.5) // MINI: 50%
            case .more:
                return .white.opacity(0.75) // MORE: 75%
            case .max:
                return .white // MAX: 100%
            case .none:
                return .white.opacity(0.1)
            }
        }

        // 오늘 날짜이고 기록이 없으면 약간 밝게
        if index + 1 == currentDay {
            return .white.opacity(0.3) // 오늘은 약간 밝게
        }

        // 미완료
        return .white.opacity(0.1)
    }
}

// MARK: - 레벨 버튼
struct LevelButton: View {
    let level: CompletionLevel
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(level.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .black : .white)
                
                Text("\(count)")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .black : .white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.2))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 오늘의 액션 버튼들
struct TodayActionButtons: View {
    let habit: Habit
    let viewModel: HabitViewModel
    @Binding var selectedLevel: CompletionLevel
    
    var body: some View {
        HStack(spacing: 12) {
            // 어제, 오늘 SKIP 버튼들
            Button("11일 (토) SKIP") {
                // SKIP 로직
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            
            Button("12일 (일) SKIP") {
                // SKIP 로직
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            
            Spacer()
            
                    // TODAY 버튼
                    NavigationLink(destination: HabitCheckView(habit: habit, viewModel: viewModel)) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                            Text("TODAY")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(16)
                    }
        }
    }
}

struct MinimalHabitCard: View {
    let habit: Habit
    let viewModel: HabitViewModel
    
    @State private var selectedLevel: CompletionLevel = .none
    
    var body: some View {
        NavigationLink(destination: HabitDetailView(habit: habit, viewModel: viewModel)) {
            ZStack {
                // 그라데이션 배경
                LinearGradient(
                    colors: [
                        Color(hex: habit.colorHex),
                        Color(hex: habit.colorHex).opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(24)
                
                VStack(alignment: .leading, spacing: 16) {
                    // 상단: 제목 & 통계
                    HStack {
                        // 불꽃 + 연속 달성
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.white)
                            Text("\(viewModel.getCurrentStreak(for: habit))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.2))
                        .cornerRadius(12)
                        
                        Spacer()
                        
                        // 통계 버튼들
                        HStack(spacing: 12) {
                            StatButton(icon: "calendar", value: "\(currentCycleDay)")
                            StatButton(icon: "checkmark.circle", value: "\(completedDays)")
                        }
                    }
                    
                    // 습관 제목
                    Text(habit.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 8)
                    
                    // 20일 프로그레스 도트
                    TwentyDayProgress(records: cycleRecords, currentDay: currentCycleDay)
                    
                    // 레벨 통계
                    HStack(spacing: 20) {
                        LevelStat(level: "MINI", count: levelCounts.mini, total: 20)
                        LevelStat(level: "MORE", count: levelCounts.more, total: 20)
                        LevelStat(level: "MAX", count: levelCounts.max, total: 20)
                        
                        Spacer()
                        
                        // 오늘 선택된 레벨 표시
                        TodayLevelSelector(
                            selectedLevel: $selectedLevel,
                            onSelect: { level in
                                viewModel.updateRecord(for: habit, level: level)
                            }
                        )
                    }
                }
                .padding(20)
            }
            .frame(height: 280)
        }
        .buttonStyle(.plain)
        .onAppear {
            selectedLevel = viewModel.getTodayRecord(for: habit)?.level ?? .none
        }
    }
    
    private var cycleRecords: [CompletionLevel?] {
        let calendar = Calendar.current
        let startDate = getCurrentCycleStartDate()
        
        var records: [CompletionLevel?] = []
        for day in 0..<20 {
            guard let date = calendar.date(byAdding: .day, value: day, to: startDate) else {
                records.append(nil)
                continue
            }
            
            let dayStart = calendar.startOfDay(for: date)
            let record = habit.records.first { record in
                calendar.isDate(record.date, inSameDayAs: dayStart)
            }
            records.append(record?.level)
        }
        return records
    }
    
    private var currentCycleDay: Int {
        let calendar = Calendar.current
        let startDate = getCurrentCycleStartDate()
        let dayInCycle = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return min(dayInCycle + 1, 20)
    }
    
    private var completedDays: Int {
        cycleRecords.filter { $0 != nil && $0 != .none }.count
    }
    
    private var levelCounts: (mini: Int, more: Int, max: Int) {
        viewModel.getLevelCounts(for: habit)
    }
    
    private func getCurrentCycleStartDate() -> Date {
        let calendar = Calendar.current
        let daysSinceStart = calendar.dateComponents([.day], from: habit.startDate, to: Date()).day ?? 0
        let currentCycleIndex = max(0, daysSinceStart / 20)
        return calendar.date(byAdding: .day, value: currentCycleIndex * 20, to: habit.startDate)!
    }
}

struct StatButton: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(value)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.white.opacity(0.9))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.15))
        .cornerRadius(8)
    }
}

struct TwentyDayProgress: View {
    let records: [CompletionLevel?]
    let currentDay: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: 12, height: 12)
                    .overlay {
                        if index + 1 == currentDay && records[index] == nil {
                            Circle()
                                .strokeBorder(.white, lineWidth: 2)
                        }
                    }
            }
        }
    }
    
    private func dotColor(for index: Int) -> Color {
        if index >= currentDay {
            return .white.opacity(0.2)
        }
        
        guard let level = records[index], level != .none else {
            return .white.opacity(0.3)
        }
        
        return .white
    }
}

struct LevelStat: View {
    let level: String
    let count: Int
    let total: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(level)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 4) {
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(total)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

struct TodayLevelSelector: View {
    @Binding var selectedLevel: CompletionLevel
    let onSelect: (CompletionLevel) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            LevelCircleButton(level: .mini, isSelected: selectedLevel == .mini) {
                selectedLevel = .mini
                onSelect(.mini)
            }
            
            LevelCircleButton(level: .max, isSelected: selectedLevel == .max) {
                selectedLevel = .max
                onSelect(.max)
            }
            
            LevelCircleButton(level: .more, isSelected: selectedLevel == .more) {
                selectedLevel = .more
                onSelect(.more)
            }
        }
    }
}

struct LevelCircleButton: View {
    let level: CompletionLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? .white : .white.opacity(0.3))
                    .frame(width: 44, height: 44)
                
                Text(levelText)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? Color(hex: "FF6B4A") : .white)
                
                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 3)
                        .frame(width: 52, height: 52)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var levelText: String {
        switch level {
        case .skip: return "SKIP"
        case .mini: return "MINI"
        case .more: return "MORE"
        case .max: return "MAX"
        case .none: return ""
        }
    }
}

struct EmptyStateView: View {
    let onAddTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 8) {
                Text("습관을 추가해보세요")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("작심삼일은 당신 탓이 아니에요!\n유연한 3단계 목표로 시작해보세요")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onAddTapped) {
                Label("습관 추가하기", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Habit.self, DailyRecord.self], inMemory: true)
}
