import Foundation
import SwiftData

@Model
class DailyRecord {
    var id: UUID
    var date: Date
    var levelRawValue: String
    var memo: String?
    var selectedItems: [String] // 선택된 항목들
    var habit: Habit?
    
    var level: CompletionLevel {
        get {
            CompletionLevel(rawValue: levelRawValue) ?? .none
        }
        set {
            levelRawValue = newValue.rawValue
        }
    }
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        level: CompletionLevel = .none,
        memo: String? = nil,
        selectedItems: [String] = [],
        habit: Habit? = nil
    ) {
        self.id = id
        self.date = date
        self.levelRawValue = level.rawValue
        self.memo = memo
        self.selectedItems = selectedItems
        self.habit = habit
    }
}

