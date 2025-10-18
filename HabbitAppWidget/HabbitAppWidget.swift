import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct HabitEntry: TimelineEntry {
    let date: Date
    let habits: [HabitWidgetData]
}

struct HabitWidgetData: Identifiable {
    let id: UUID
    let title: String
    let todayLevel: CompletionLevel
    let cycleRecords: [CompletionLevel?] // 20일 사이클 기록
    let currentCycleDay: Int // 현재 사이클의 Day (1~20)
    let completedDays: Int // 완료한 일수
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        let sampleRecords: [CompletionLevel?] = [
            .mini, .more, .max, .mini, .none, .more, .max, .mini, .more, .max,
            .mini, .more, nil, nil, nil, nil, nil, nil, nil, nil
        ]

        return HabitEntry(date: Date(), habits: [
            HabitWidgetData(
                id: UUID(),
                title: "스페인어 학습",
                todayLevel: .none,
                cycleRecords: sampleRecords,
                currentCycleDay: 12,
                completedDays: 10
            )
        ])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        let entry = HabitEntry(date: Date(), habits: fetchHabits())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        let habits = fetchHabits()
        let entry = HabitEntry(date: Date(), habits: habits)
        
        // 다음 날 자정에 업데이트
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let midnight = calendar.startOfDay(for: tomorrow)
        
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
    
    private func fetchHabits() -> [HabitWidgetData] {
        // SwiftData에서 습관 가져오기
        // App Group을 통해 공유된 데이터 접근
        let schema = Schema([
            Habit.self,
            DailyRecord.self,
            CycleHistory.self,
        ])

        // 먼저 App Group 없이 시도 (개발 중)
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        guard let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else {
            print("⚠️ Widget: Failed to create ModelContainer")
            return []
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        guard let habits = try? context.fetch(descriptor) else {
            print("⚠️ Widget: Failed to fetch habits")
            return []
        }

        print("✅ Widget: Found \(habits.count) habits")

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return habits.prefix(2).map { habit in
            let todayRecord = habit.records.first { record in
                calendar.isDate(record.date, inSameDayAs: today)
            }

            // 20일 사이클 계산
            let cycleRecords = getCycleRecords(for: habit, calendar: calendar)
            let currentCycleDay = getCurrentCycleDay(for: habit, calendar: calendar)
            let completedDays = cycleRecords.filter { $0 != nil && $0 != .none }.count

            return HabitWidgetData(
                id: habit.id,
                title: habit.title,
                todayLevel: todayRecord?.level ?? .none,
                cycleRecords: cycleRecords,
                currentCycleDay: currentCycleDay,
                completedDays: completedDays
            )
        }
    }

    private func getCycleRecords(for habit: Habit, calendar: Calendar) -> [CompletionLevel?] {
        let startDate = getCurrentCycleStartDate(for: habit, calendar: calendar)

        var records: [CompletionLevel?] = []

        for day in 0..<20 {
            guard let date = calendar.date(byAdding: .day, value: day, to: startDate) else {
                records.append(nil)
                continue
            }

            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let record = habit.records.first { record in
                record.date >= dayStart && record.date < dayEnd
            }

            records.append(record?.level)
        }

        return records
    }

    private func getCurrentCycleStartDate(for habit: Habit, calendar: Calendar) -> Date {
        let daysSinceStart = calendar.dateComponents([.day], from: habit.startDate, to: Date()).day ?? 0
        let currentCycleIndex = max(0, daysSinceStart / 20)
        return calendar.date(byAdding: .day, value: currentCycleIndex * 20, to: habit.startDate)!
    }

    private func getCurrentCycleDay(for habit: Habit, calendar: Calendar) -> Int {
        let startDate = getCurrentCycleStartDate(for: habit, calendar: calendar)
        let dayInCycle = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return min(dayInCycle + 1, 20)
    }
}

struct HabbitAppWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(habit: entry.habits.first)
        case .systemMedium:
            MediumWidgetView(habits: entry.habits)
        case .systemLarge:
            LargeWidgetView(habit: entry.habits.first)
        default:
            SmallWidgetView(habit: entry.habits.first)
        }
    }
}

struct SmallWidgetView: View {
    let habit: HabitWidgetData?

    var body: some View {
        ZStack {
            Color(.systemBackground)

            if let habit = habit {
                VStack(alignment: .leading, spacing: 8) {
                    // 제목 & 진행도
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.title)
                                .font(.headline)
                                .fontWeight(.bold)
                                .lineLimit(2)
                                .foregroundColor(.primary)

                            Text("Day \(habit.currentCycleDay)/20")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // 미니 원형 진행도
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 3)

                            Circle()
                                .trim(from: 0, to: Double(habit.completedDays) / 20.0)
                                .stroke(progressColor(for: habit.completedDays), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))

                            Text("\(habit.completedDays)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(progressColor(for: habit.completedDays))
                        }
                        .frame(width: 32, height: 32)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        LevelIndicator(level: .mini, isCompleted: habit.todayLevel == .mini)
                        LevelIndicator(level: .more, isCompleted: habit.todayLevel == .more)
                        LevelIndicator(level: .max, isCompleted: habit.todayLevel == .max)
                    }
                }
                .padding()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    Text("습관 추가")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func progressColor(for completedDays: Int) -> Color {
        let progress = Double(completedDays) / 20.0
        if progress >= 0.75 {
            return .green
        } else if progress >= 0.5 {
            return .blue
        } else if progress >= 0.25 {
            return .orange
        } else {
            return .red
        }
    }
}

struct MediumWidgetView: View {
    let habits: [HabitWidgetData]

    var body: some View {
        if habits.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle")
                    .font(.largeTitle)
                    .foregroundStyle(.blue.gradient)
                Text("오늘의 습관")
                    .font(.headline)
                Text("앱에서 습관을 추가하세요")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("오늘의 습관")
                    .font(.headline)

                ForEach(habits.prefix(2)) { habit in
                    HabitRowWidget(habit: habit)
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct HabitRowWidget: View {
    let habit: HabitWidgetData

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(habit.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Text("Day \(habit.currentCycleDay)/20")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    LevelIndicator(level: .mini, isCompleted: habit.todayLevel == .mini)
                    LevelIndicator(level: .more, isCompleted: habit.todayLevel == .more)
                    LevelIndicator(level: .max, isCompleted: habit.todayLevel == .max)

                    Spacer()

                    // 간단한 진행도 바
                    ProgressBar(completed: habit.completedDays, total: 20)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.systemBackground).opacity(0.5))
        .cornerRadius(8)
    }
}

struct ProgressBar: View {
    let completed: Int
    let total: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(progressColor)
                    .frame(width: geometry.size.width * progress, height: 4)
            }
        }
        .frame(width: 50, height: 4)
    }

    private var progress: Double {
        Double(completed) / Double(total)
    }

    private var progressColor: Color {
        if progress >= 0.75 {
            return .green
        } else if progress >= 0.5 {
            return .blue
        } else if progress >= 0.25 {
            return .orange
        } else {
            return .red
        }
    }
}

struct LargeWidgetView: View {
    let habit: HabitWidgetData?

    var body: some View {
        if let habit = habit {
            VStack(alignment: .leading, spacing: 12) {
                // 헤더
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(habit.title)
                            .font(.headline)
                            .fontWeight(.bold)

                        Text("Day \(habit.currentCycleDay)/20 · \(habit.completedDays)일 완료")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // 완료율
                    VStack(spacing: 2) {
                        Text("\(Int(Double(habit.completedDays) / 20.0 * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(progressColor(for: habit.completedDays))

                        Text("완료율")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // 20일 달력 그리드
                TwentyDayCalendarGrid(records: habit.cycleRecords, currentDay: habit.currentCycleDay)

                Spacer()
            }
            .padding()
        } else {
            VStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.largeTitle)
                    .foregroundStyle(.blue.gradient)
                Text("20일 습관 챌린지")
                    .font(.headline)
                Text("앱에서 습관을 추가하세요")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func progressColor(for completedDays: Int) -> Color {
        let progress = Double(completedDays) / 20.0
        if progress >= 0.75 {
            return .green
        } else if progress >= 0.5 {
            return .blue
        } else if progress >= 0.25 {
            return .orange
        } else {
            return .red
        }
    }
}

struct TwentyDayCalendarGrid: View {
    let records: [CompletionLevel?]
    let currentDay: Int

    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        VStack(spacing: 8) {
            // 그리드 (4행 5열 = 20일)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<20, id: \.self) { index in
                    DayCell(
                        day: index + 1,
                        level: records[index],
                        isToday: index + 1 == currentDay
                    )
                }
            }

            // 범례
            HStack(spacing: 12) {
                LegendItem(color: .white.opacity(0.5), label: "MINI")
                LegendItem(color: .white.opacity(0.6), label: "MORE")
                LegendItem(color: .white, label: "MAX")
                LegendItem(color: .white.opacity(0.2), label: "미완료")
            }
            .font(.caption2)
        }
    }

    private func hexColor(_ hex: String) -> Color {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        return Color(red: r, green: g, blue: b)
    }
}

struct DayCell: View {
    let day: Int
    let level: CompletionLevel?
    let isToday: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(cellColor)
                .aspectRatio(1, contentMode: .fit)

            if isToday {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.white, lineWidth: 2)
            }

            VStack(spacing: 2) {
                Text("\(day)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(textColor)
                
                if let level = level, level != .none {
                    Text(level.displayName)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(textColor)
                } else if isToday {
                    Text("TODAY")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }

    private var cellColor: Color {
        guard let level = level else {
            return .white.opacity(0.1) // 미완료는 10% 흰색
        }

        switch level {
        case .skip:
            return .white.opacity(0.1) // SKIP은 10% 흰색
        case .mini:
            return .white.opacity(0.5) // MINI는 50% 흰색 (조금 더 진하게)
        case .more:
            return .white.opacity(0.6) // MORE는 60% 흰색 (중간)
        case .max:
            return .white // MAX는 순백색 (가장 진함)
        case .none:
            return .white.opacity(0.2) // 미완료는 20% 흰색
        }
    }

    private var textColor: Color {
        if level == nil || level == .none {
            return .white.opacity(0.3) // 미완료는 연한 흰색
        }
        return .black // 완료된 날은 검은색 텍스트 (흰색 배경에)
    }

    private func hexColor(_ hex: String) -> Color {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        return Color(red: r, green: g, blue: b)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)

            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

struct LevelIndicator: View {
    let level: CompletionLevel
    let isCompleted: Bool

    var body: some View {
        Circle()
            .fill(isCompleted ? levelColor : Color.gray.opacity(0.3))
            .frame(width: 12, height: 12)
            .overlay {
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(.white)
                }
            }
    }

    private var levelColor: Color {
        switch level {
        case .skip:
            return .white.opacity(0.1) // SKIP은 10% 흰색
        case .mini:
            return .white.opacity(0.5) // MINI는 50% 흰색 (조금 더 진하게)
        case .more:
            return .white.opacity(0.6) // MORE는 60% 흰색 (중간)
        case .max:
            return .white // MAX는 순백색 (가장 진함)
        case .none:
            return .white.opacity(0.2) // 미완료는 20% 흰색
        }
    }

    private func hexColor(_ hex: String) -> Color {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        return Color(red: r, green: g, blue: b)
    }
}

struct HabbitAppWidget: Widget {
    let kind: String = "HabbitAppWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HabbitAppWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("오늘의 습관")
        .description("오늘 실천할 습관을 확인하세요")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct HabbitWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabbitAppWidget()
        WeeklyProgressWidget()
    }
}

// MARK: - 주간 진행 위젯

struct WeeklyHabitData: Identifiable {
    let id: UUID
    let title: String
    let colorHex: String
    let weeklyLevels: [CompletionLevel?] // 일~토 7일간 완료 레벨
}

struct WeeklyEntry: TimelineEntry {
    let date: Date
    let habits: [WeeklyHabitData]
}

struct WeeklyProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeeklyEntry {
        WeeklyEntry(date: Date(), habits: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (WeeklyEntry) -> Void) {
        let entry = WeeklyEntry(date: Date(), habits: fetchWeeklyHabits())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyEntry>) -> Void) {
        let habits = fetchWeeklyHabits()
        let entry = WeeklyEntry(date: Date(), habits: habits)

        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let midnight = calendar.startOfDay(for: tomorrow)

        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }

    private func fetchWeeklyHabits() -> [WeeklyHabitData] {
        let schema = Schema([Habit.self, DailyRecord.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        guard let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else {
            return []
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        guard let habits = try? context.fetch(descriptor) else {
            return []
        }

        let calendar = Calendar.current
        let today = Date()

        // 이번 주 일요일 찾기
        let weekday = calendar.component(.weekday, from: today)
        let daysToSunday = (weekday - 1)
        guard let sunday = calendar.date(byAdding: .day, value: -daysToSunday, to: today) else {
            return []
        }
        let sundayStart = calendar.startOfDay(for: sunday)

        return habits.prefix(4).map { habit in
            var weeklyLevels: [CompletionLevel?] = []

            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: sundayStart) else {
                    weeklyLevels.append(nil)
                    continue
                }

                let dayStart = calendar.startOfDay(for: date)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

                let record = habit.records.first { record in
                    record.date >= dayStart && record.date < dayEnd
                }

                weeklyLevels.append(record?.level)
            }

            return WeeklyHabitData(
                id: habit.id,
                title: habit.title,
                colorHex: habit.colorHex,
                weeklyLevels: weeklyLevels
            )
        }
    }
}

struct WeeklyProgressWidgetView: View {
    var entry: WeeklyProvider.Entry

    // 고정 상수
    private let habitNameWidth: CGFloat = 70
    private let horizontalPadding: CGFloat = 10
    private let boxSpacing: CGFloat = 3

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - (horizontalPadding * 2) - habitNameWidth
            let totalSpacing = boxSpacing * 6 // 7개 박스 사이 6개 간격
            let boxWidth = (availableWidth - totalSpacing) / 7

            VStack(spacing: 0) {
                // 요일 헤더
                HStack(spacing: 0) {
                    // 습관 이름 영역
                    Text("")
                        .frame(width: habitNameWidth, alignment: .leading)

                    // 요일 영역 (박스와 정확히 동일한 크기)
                    HStack(spacing: boxSpacing) {
                        ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                            Text(day)
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(width: boxWidth * 0.85)
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 4)

                // 습관 목록
                if entry.habits.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("습관을 추가하세요")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    VStack(spacing: 5) {
                        ForEach(entry.habits) { habit in
                            HStack(spacing: 0) {
                                // 습관 이름
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(Color(hex: habit.colorHex))
                                        .frame(width: 10, height: 10)

                                     Text(habit.title)
                                         .font(.system(size: 9))
                                         .foregroundColor(.primary)
                                         .lineLimit(1)
                                }
                                .frame(width: habitNameWidth, alignment: .leading)

                                // 주간 완료 박스
                                HStack(spacing: boxSpacing) {
                                    ForEach(0..<7, id: \.self) { index in
                                        RoundedRectangle(cornerRadius: 2.5)
                                            .fill(boxColor(for: habit.weeklyLevels[index], habitColor: habit.colorHex))
                                            .frame(width: boxWidth * 0.85, height: boxWidth * 0.85)
                                    }
                                }
                            }
                            .padding(.horizontal, horizontalPadding)
                        }
                    }
                    .padding(.bottom, 6)
                }
            }
        }
    }

    private func boxColor(for level: CompletionLevel?, habitColor: String) -> Color {
        guard let level = level else {
            return Color.gray.opacity(0.15)
        }

        switch level {
        case .skip, .none:
            return Color.gray.opacity(0.15)
        case .mini:
            return Color(hex: habitColor).opacity(0.5)
        case .more:
            return Color(hex: habitColor).opacity(0.75)
        case .max:
            return Color(hex: habitColor)
        }
    }
}

// MARK: - 주간 박스
struct WeekDayBox: View {
    let level: CompletionLevel?
    let habitColor: String

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(boxColor)
            .aspectRatio(1, contentMode: .fit)
    }

    private var boxColor: Color {
        guard let level = level else {
            return Color.gray.opacity(0.15)
        }

        switch level {
        case .skip, .none:
            return Color.gray.opacity(0.15)
        case .mini:
            return Color(hex: habitColor).opacity(0.5) // 50%
        case .more:
            return Color(hex: habitColor).opacity(0.75) // 75%
        case .max:
            return Color(hex: habitColor) // 100%
        }
    }
}

struct WeeklyProgressWidget: Widget {
    let kind: String = "WeeklyProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyProvider()) { entry in
            WeeklyProgressWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("주간 진행 상황")
        .description("이번 주 습관 실천 현황")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemSmall) {
    HabbitAppWidget()
} timeline: {
    let sampleRecords: [CompletionLevel?] = [
        .mini, .more, .max, .mini, .none, .more, .max, .mini, .more, .max,
        .mini, .more, nil, nil, nil, nil, nil, nil, nil, nil
    ]

    HabitEntry(date: .now, habits: [
        HabitWidgetData(
            id: UUID(),
            title: "스페인어 학습",
            todayLevel: .more,
            cycleRecords: sampleRecords,
            currentCycleDay: 12,
            completedDays: 10
        )
    ])
}

#Preview(as: .systemMedium) {
    HabbitAppWidget()
} timeline: {
    let sampleRecords1: [CompletionLevel?] = [
        .mini, .more, .max, .mini, .none, .more, .max, .mini, .more, .max,
        .mini, .more, nil, nil, nil, nil, nil, nil, nil, nil
    ]
    let sampleRecords2: [CompletionLevel?] = [
        .max, .max, .more, .mini, .more, .max, .none, .mini, .more, nil,
        nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
    ]

    HabitEntry(date: .now, habits: [
        HabitWidgetData(
            id: UUID(),
            title: "스페인어 학습",
            todayLevel: .more,
            cycleRecords: sampleRecords1,
            currentCycleDay: 12,
            completedDays: 10
        ),
        HabitWidgetData(
            id: UUID(),
            title: "운동하기",
            todayLevel: .none,
            cycleRecords: sampleRecords2,
            currentCycleDay: 9,
            completedDays: 7
        )
    ])
}

#Preview(as: .systemLarge) {
    HabbitAppWidget()
} timeline: {
    let sampleRecords: [CompletionLevel?] = [
        .mini, .more, .max, .mini, .none, .more, .max, .mini, .more, .max,
        .mini, .more, nil, nil, nil, nil, nil, nil, nil, nil
    ]

    HabitEntry(date: .now, habits: [
        HabitWidgetData(
            id: UUID(),
            title: "스페인어 학습",
            todayLevel: .more,
            cycleRecords: sampleRecords,
            currentCycleDay: 12,
            completedDays: 10
        )
    ])
}
