import Foundation
import SwiftData

@Model
class Habit {
    var id: UUID
    var title: String
    var startDate: Date
    var isActive: Bool
    var currentCycle: Int // 현재 사이클 번호 (1부터 시작)
    var completedCycles: Int // 완료한 20일 사이클 수
    var colorHex: String // 습관 색상 (hex 코드)
    var isWaitingForNextCycle: Bool // 20일 완료 후 다음 회차 대기 상태

    // 각 레벨별 항목들 (목표가 곧 항목)
    var miniItems: [String] // MINI 레벨 항목들
    var moreItems: [String] // MORE 레벨 항목들
    var maxItems: [String] // MAX 레벨 항목들

    // 리마인더 설정
    var reminderEnabled: Bool // 리마인더 활성화 여부
    var reminderTime: Date? // 리마인더 시간 (시:분만 사용)
    
    // 이모지
    var emoji: String // 습관 이모지

    @Relationship(deleteRule: .cascade)
    var records: [DailyRecord]

    @Relationship(deleteRule: .cascade)
    var cycleHistories: [CycleHistory] // 완료된 회차 히스토리

    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date = Date(),
        isActive: Bool = true,
        currentCycle: Int = 1,
        completedCycles: Int = 0,
        colorHex: String = "FF6B4A", // 기본 주황색
        miniItems: [String] = [],
        moreItems: [String] = [],
        maxItems: [String] = [],
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil,
        emoji: String = "⭐️", // 기본 이모지
        records: [DailyRecord] = [],
        cycleHistories: [CycleHistory] = []
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.isActive = isActive
        self.currentCycle = currentCycle
        self.completedCycles = completedCycles
        self.colorHex = colorHex
        self.miniItems = miniItems
        self.moreItems = moreItems
        self.maxItems = maxItems
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.emoji = emoji
        self.records = records
        self.cycleHistories = cycleHistories
        self.isWaitingForNextCycle = false
    }
}

@Model
class CycleHistory {
    var id: UUID
    var cycleNumber: Int // 회차 번호 (1, 2, 3, ...)
    var startDate: Date // 사이클 시작일
    var endDate: Date // 사이클 종료일
    var completedDays: Int // 완료한 일수 (0~20)
    var isSuccessful: Bool // 15일 이상 완료 여부

    // 레벨별 횟수
    var miniCount: Int
    var moreCount: Int
    var maxCount: Int
    var skipCount: Int

    // 관계
    var habit: Habit?

    init(
        id: UUID = UUID(),
        cycleNumber: Int,
        startDate: Date,
        endDate: Date,
        completedDays: Int,
        isSuccessful: Bool,
        miniCount: Int,
        moreCount: Int,
        maxCount: Int,
        skipCount: Int,
        habit: Habit? = nil
    ) {
        self.id = id
        self.cycleNumber = cycleNumber
        self.startDate = startDate
        self.endDate = endDate
        self.completedDays = completedDays
        self.isSuccessful = isSuccessful
        self.miniCount = miniCount
        self.moreCount = moreCount
        self.maxCount = maxCount
        self.skipCount = skipCount
        self.habit = habit
    }
}
