import Foundation
import SwiftData
import WidgetKit
import SwiftUI

@Observable
class HabitViewModel {
    var habits: [Habit] = []
    var selectedDate: Date = Date()
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchHabits()
    }
    
    // MARK: - Habit CRUD
    
    func fetchHabits() {
        print("🔄 습관 목록 가져오기 시작")
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        do {
            habits = try modelContext.fetch(descriptor)
            print("✅ 습관 목록 가져오기 완료, 습관 수: \(habits.count)")
            for habit in habits {
                print("  - \(habit.title) (시작일: \(habit.startDate))")
            }
        } catch {
            print("❌ 습관 목록 가져오기 실패: \(error)")
        }
    }
    
    // 이 메서드는 더 이상 사용하지 않음 - addHabitSimple 사용
    
    func addHabitSimple(
        title: String,
        startDate: Date = Date(),
        colorHex: String = "FF6B4A",
        miniItems: [String] = [],
        moreItems: [String] = [],
        maxItems: [String] = [],
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil,
        emoji: String = "⭐️"
    ) -> Habit? {
        print("🔄 습관 추가 시작: \(title)")
        print("   - MINI 항목: \(miniItems)")
        print("   - MORE 항목: \(moreItems)")
        print("   - MAX 항목: \(maxItems)")
        print("   - 시작일: \(startDate)")
        print("   - 리마인더: \(reminderEnabled)")

        let newHabit = Habit(
            title: title,
            startDate: startDate,
            colorHex: colorHex,
            miniItems: miniItems,
            moreItems: moreItems,
            maxItems: maxItems,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime,
            emoji: emoji
        )

        print("✅ Habit 객체 생성됨 - ID: \(newHabit.id)")

        modelContext.insert(newHabit)
        print("✅ modelContext.insert() 완료")

        do {
            try modelContext.save()
            print("✅ modelContext.save() 완료")

            // 저장 직후 바로 확인
            let descriptor = FetchDescriptor<Habit>()
            let allHabits = try modelContext.fetch(descriptor)
            print("✅ 데이터베이스 전체 습관 수: \(allHabits.count)")
            for h in allHabits {
                print("   - \(h.title) (isActive: \(h.isActive))")
            }

            fetchHabits()
            print("✅ fetchHabits() 완료, viewModel.habits.count: \(habits.count)")
            return newHabit
        } catch {
            print("❌ 습관 저장 실패: \(error)")
            print("❌ 에러 상세: \(error.localizedDescription)")
            return nil
        }
    }
    
    func deleteHabit(_ habit: Habit) {
        // 리마인더 취소
        Task {
            await NotificationManager.shared.cancelHabitReminder(for: habit)
        }
        
        modelContext.delete(habit)
        
        do {
            try modelContext.save()
            fetchHabits()
            print("✅ 습관 삭제 완료: \(habit.title)")
        } catch {
            print("❌ 습관 삭제 실패: \(error)")
        }
    }
    
    // updateHabit는 더 이상 사용하지 않음 - 직접 habit 속성 수정
    
    // MARK: - Daily Record
    
    func getTodayRecord(for habit: Habit) -> DailyRecord? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: selectedDate)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        
        return habit.records.first { record in
            record.date >= startOfToday && record.date < endOfToday
        }
    }
    
    func updateRecord(for habit: Habit, level: CompletionLevel, memo: String? = nil) {
        if let existingRecord = getTodayRecord(for: habit) {
            existingRecord.level = level
            existingRecord.memo = memo
        } else {
            let newRecord = DailyRecord(
                date: selectedDate,
                level: level,
                memo: memo,
                habit: habit
            )
            modelContext.insert(newRecord)
            habit.records.append(newRecord)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save record: \(error)")
        }
    }
    
    // MARK: - Statistics
    
    func getCompletionRate(for habit: Habit) -> Double {
        let completedRecords = habit.records.filter { $0.level != .none }
        guard !habit.records.isEmpty else { return 0 }
        return Double(completedRecords.count) / Double(habit.records.count)
    }
    
    func getCurrentStreak(for habit: Habit) -> Int {
        let calendar = Calendar.current
        let sortedRecords = habit.records
            .filter { $0.level != .none }
            .sorted { $0.date > $1.date }
        
        guard !sortedRecords.isEmpty else { return 0 }
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for record in sortedRecords {
            let recordDate = calendar.startOfDay(for: record.date)
            
            if recordDate == currentDate {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if recordDate < currentDate {
                break
            }
        }
        
        return streak
    }
    
    func getLevelCounts(for habit: Habit) -> (mini: Int, more: Int, max: Int) {
        let miniCount = habit.records.filter { $0.level == .mini }.count
        let moreCount = habit.records.filter { $0.level == .more }.count
        let maxCount = habit.records.filter { $0.level == .max }.count
        
        return (miniCount, moreCount, maxCount)
    }
    
    func getDaysFromStart(for habit: Habit) -> Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: habit.startDate, to: Date()).day ?? 0
        return max(days, 0)
    }

    // MARK: - 20-Day Cycle

    /// 현재 사이클의 시작일 계산
    func getCurrentCycleStartDate(for habit: Habit) -> Date {
        let calendar = Calendar.current
        let daysSinceStart = calendar.dateComponents([.day], from: habit.startDate, to: Date()).day ?? 0
        let currentCycleIndex = max(0, daysSinceStart / 20)
        return calendar.date(byAdding: .day, value: currentCycleIndex * 20, to: habit.startDate)!
    }

    /// 현재 사이클의 종료일 계산
    func getCurrentCycleEndDate(for habit: Habit) -> Date {
        let calendar = Calendar.current
        let startDate = getCurrentCycleStartDate(for: habit)
        return calendar.date(byAdding: .day, value: 19, to: startDate)!
    }

    /// 현재 사이클의 진행 일수 (1~20)
    func getCurrentCycleDay(for habit: Habit) -> Int {
        let calendar = Calendar.current
        let startDate = getCurrentCycleStartDate(for: habit)
        let dayInCycle = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return min(dayInCycle + 1, 20)
    }

    /// 현재 사이클의 20일 기록 가져오기
    func getCurrentCycleRecords(for habit: Habit) -> [DailyRecord?] {
        let calendar = Calendar.current
        let startDate = getCurrentCycleStartDate(for: habit)

        var records: [DailyRecord?] = []

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

            records.append(record)
        }

        return records
    }

    /// 현재 사이클의 완료 일수
    func getCurrentCycleCompletedDays(for habit: Habit) -> Int {
        let records = getCurrentCycleRecords(for: habit)
        return records.filter { $0?.level != nil && $0?.level != .none }.count
    }

    /// 현재 사이클의 완료율 (0.0 ~ 1.0)
    func getCurrentCycleCompletionRate(for habit: Habit) -> Double {
        let completedDays = getCurrentCycleCompletedDays(for: habit)
        return Double(completedDays) / 20.0
    }

    /// 습관 완료 처리
    func completeHabit(_ habit: Habit, level: CompletionLevel, date: Date) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        // 기존 기록이 있는지 확인
        if let existingRecord = habit.records.first(where: { record in
            calendar.isDate(record.date, inSameDayAs: dayStart)
        }) {
            // 기존 기록 업데이트
            existingRecord.level = level
        } else {
            // 새 기록 생성
            let newRecord = DailyRecord(
                date: dayStart,
                level: level,
                memo: ""
            )
            habit.records.append(newRecord)
        }
        
        do {
            try modelContext.save()
            fetchHabits() // UI 업데이트
        } catch {
            print("❌ 습관 완료 저장 실패: \(error)")
        }
    }
    
    /// 습관 완료 처리 (항목과 메모 포함)
    func completeHabitWithItems(_ habit: Habit, level: CompletionLevel, selectedItems: [String], memo: String?, date: Date) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        // 기존 기록이 있는지 확인
        if let existingRecord = habit.records.first(where: { record in
            calendar.isDate(record.date, inSameDayAs: dayStart)
        }) {
            // 기존 기록 업데이트
            existingRecord.level = level
            existingRecord.selectedItems = selectedItems
            existingRecord.memo = memo
        } else {
            // 새 기록 생성
            let newRecord = DailyRecord(
                date: dayStart,
                level: level,
                memo: memo,
                selectedItems: selectedItems
            )
            habit.records.append(newRecord)
        }

        do {
            try modelContext.save()
            fetchHabits() // UI 업데이트

            // 위젯 업데이트
            WidgetCenter.shared.reloadAllTimelines()
            print("✅ 위젯 리로드 요청됨")
        } catch {
            print("❌ 습관 완료 저장 실패: \(error)")
        }
    }
    
    /// 20일 사이클 완료 여부 확인 및 업데이트
    func checkAndUpdateCycleCompletion(for habit: Habit) {
        let cycleEndDate = getCurrentCycleEndDate(for: habit)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDay = calendar.startOfDay(for: cycleEndDate)

        // 현재 날짜가 사이클 종료일 다음 날인지 확인
        if today > endDay && !habit.isWaitingForNextCycle {
            // 대기 상태로 전환
            habit.isWaitingForNextCycle = true

            // CycleHistory 생성
            let cycleRecords = getCurrentCycleRecords(for: habit)
            let completedDays = cycleRecords.filter { $0?.level != nil && $0?.level != .none }.count
            let miniCount = cycleRecords.filter { $0?.level == .mini }.count
            let moreCount = cycleRecords.filter { $0?.level == .more }.count
            let maxCount = cycleRecords.filter { $0?.level == .max }.count
            let skipCount = cycleRecords.filter { $0?.level == .skip }.count
            let isSuccessful = completedDays >= 15

            let history = CycleHistory(
                cycleNumber: habit.currentCycle,
                startDate: getCurrentCycleStartDate(for: habit),
                endDate: cycleEndDate,
                completedDays: completedDays,
                isSuccessful: isSuccessful,
                miniCount: miniCount,
                moreCount: moreCount,
                maxCount: maxCount,
                skipCount: skipCount,
                habit: habit
            )

            modelContext.insert(history)
            habit.cycleHistories.append(history)

            if isSuccessful {
                habit.completedCycles += 1
            }

            do {
                try modelContext.save()
                print("✅ 회차 완료 처리: \(habit.title) - \(habit.currentCycle)회차")
            } catch {
                print("❌ Failed to update cycle: \(error)")
            }
        }
    }

    /// 다음 회차 시작
    func startNextCycle(for habit: Habit) {
        habit.currentCycle += 1
        habit.isWaitingForNextCycle = false

        do {
            try modelContext.save()
            fetchHabits() // UI 업데이트
            print("✅ 다음 회차 시작: \(habit.title) - \(habit.currentCycle)회차")
        } catch {
            print("❌ Failed to start next cycle: \(error)")
        }
    }

    /// 특정 회차의 히스토리 가져오기
    func getCycleHistory(for habit: Habit, cycle: Int) -> CycleHistory? {
        return habit.cycleHistories.first { $0.cycleNumber == cycle }
    }

    /// 전체 회차 통합 통계
    func getAllCyclesStats(for habit: Habit) -> (totalDays: Int, completedDays: Int, miniCount: Int, moreCount: Int, maxCount: Int, skipCount: Int, successfulCycles: Int) {
        let allHistories = habit.cycleHistories
        let totalDays = allHistories.reduce(0) { total, _ in total + 20 }
        let completedDays = allHistories.reduce(0) { total, history in total + history.completedDays }
        let miniCount = allHistories.reduce(0) { total, history in total + history.miniCount }
        let moreCount = allHistories.reduce(0) { total, history in total + history.moreCount }
        let maxCount = allHistories.reduce(0) { total, history in total + history.maxCount }
        let skipCount = allHistories.reduce(0) { total, history in total + history.skipCount }
        let successfulCycles = allHistories.filter { $0.isSuccessful }.count

        // 현재 진행 중인 회차도 포함 (대기 중이 아닐 경우)
        if !habit.isWaitingForNextCycle {
            let currentRecords = getCurrentCycleRecords(for: habit)
            let currentCompleted = currentRecords.filter { $0?.level != nil && $0?.level != .none }.count
            let currentMini = currentRecords.filter { $0?.level == .mini }.count
            let currentMore = currentRecords.filter { $0?.level == .more }.count
            let currentMax = currentRecords.filter { $0?.level == .max }.count
            let currentSkip = currentRecords.filter { $0?.level == .skip }.count

            return (
                totalDays: totalDays + 20,
                completedDays: completedDays + currentCompleted,
                miniCount: miniCount + currentMini,
                moreCount: moreCount + currentMore,
                maxCount: maxCount + currentMax,
                skipCount: skipCount + currentSkip,
                successfulCycles: successfulCycles
            )
        }

        return (
            totalDays: totalDays,
            completedDays: completedDays,
            miniCount: miniCount,
            moreCount: moreCount,
            maxCount: maxCount,
            skipCount: skipCount,
            successfulCycles: successfulCycles
        )
    }

    /// 파이차트 데이터 (특정 회차 또는 현재 회차)
    func getPieChartData(for habit: Habit, cycle: Int? = nil) -> (mini: Int, more: Int, max: Int, skip: Int, none: Int) {
        if let cycle = cycle, let history = getCycleHistory(for: habit, cycle: cycle) {
            // 특정 회차의 히스토리에서 데이터 가져오기
            let noneCount = 20 - history.completedDays
            return (
                mini: history.miniCount,
                more: history.moreCount,
                max: history.maxCount,
                skip: history.skipCount,
                none: noneCount
            )
        } else {
            // 현재 회차의 데이터
            let records = getCurrentCycleRecords(for: habit)
            let miniCount = records.filter { $0?.level == .mini }.count
            let moreCount = records.filter { $0?.level == .more }.count
            let maxCount = records.filter { $0?.level == .max }.count
            let skipCount = records.filter { $0?.level == .skip }.count
            let noneCount = records.filter { $0 == nil || $0?.level == .none }.count

            return (
                mini: miniCount,
                more: moreCount,
                max: maxCount,
                skip: skipCount,
                none: noneCount
            )
        }
    }

    /// 총 완료한 사이클 수
    func getTotalCompletedCycles(for habit: Habit) -> Int {
        return habit.completedCycles
    }
    
    // MARK: - Habit Update
    
    func updateHabit(
        _ habit: Habit,
        title: String,
        emoji: String,
        colorHex: String,
        startDate: Date,
        miniItems: [String],
        moreItems: [String],
        maxItems: [String],
        reminderEnabled: Bool,
        reminderTime: Date?
    ) {
        habit.title = title
        habit.emoji = emoji
        habit.colorHex = colorHex
        habit.startDate = startDate
        habit.miniItems = miniItems
        habit.moreItems = moreItems
        habit.maxItems = maxItems
        habit.reminderEnabled = reminderEnabled
        habit.reminderTime = reminderTime
        
        do {
            try modelContext.save()
            fetchHabits()
            
            // 리마인더 업데이트
            Task {
                await NotificationManager.shared.cancelHabitReminder(for: habit)
                if reminderEnabled {
                    await NotificationManager.shared.scheduleHabitReminder(for: habit)
                }
            }
            
            print("✅ 습관 수정 완료: \(habit.title)")
        } catch {
            print("❌ 습관 수정 실패: \(error)")
        }
    }
}

