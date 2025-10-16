import Foundation
import SwiftData

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
