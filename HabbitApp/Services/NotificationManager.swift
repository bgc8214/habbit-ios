import Foundation
import UserNotifications
import SwiftData

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - 권한 요청
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("❌ Notification authorization error: \(error)")
            return false
        }
    }

    // MARK: - 습관 리마인더 예약
    func scheduleHabitReminder(for habit: Habit) async {
        guard habit.reminderEnabled,
              let reminderTime = habit.reminderTime else {
            return
        }

        // 기존 알림 취소
        await cancelHabitReminder(for: habit)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)

        guard let hour = components.hour,
              let minute = components.minute else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "습관 실천 시간이에요! 💪"
        content.body = "\(habit.emoji) \(habit.title) - 오늘의 목표를 달성해보세요"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "HABIT_REMINDER"
        content.userInfo = ["habitId": habit.id.uuidString]

        // 매일 반복되는 알림
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: habit.id.uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Scheduled reminder for \(habit.emoji) \(habit.title) at \(hour):\(minute)")
        } catch {
            print("❌ Failed to schedule reminder: \(error)")
        }
    }

    // MARK: - UNUserNotificationCenterDelegate
    // 앱이 포그라운드에 있을 때 알림을 받으면 호출됨
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        // 습관 ID 가져오기
        guard let habitIdString = userInfo["habitId"] as? String,
              let habitId = UUID(uuidString: habitIdString) else {
            completionHandler([.banner, .sound, .badge])
            return
        }

        // 오늘 해당 습관을 완료했는지 확인
        if isHabitCompletedToday(habitId: habitId) {
            print("🚫 습관이 이미 완료되어 알림을 표시하지 않습니다.")
            completionHandler([]) // 알림 표시 안 함
        } else {
            print("✅ 습관이 미완료 상태이므로 알림을 표시합니다.")
            completionHandler([.banner, .sound, .badge])
        }
    }

    // 사용자가 알림을 탭했을 때 호출됨
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("📱 사용자가 알림을 탭했습니다: \(userInfo)")
        // 여기서 특정 습관 화면으로 이동하는 로직을 추가할 수 있습니다
        completionHandler()
    }

    // MARK: - Helper: 오늘 습관 완료 여부 확인
    private func isHabitCompletedToday(habitId: UUID) -> Bool {
        do {
            let modelContainer = try ModelContainer(for: Habit.self, DailyRecord.self)
            let modelContext = ModelContext(modelContainer)

            // 습관 찾기
            let descriptor = FetchDescriptor<Habit>(
                predicate: #Predicate { $0.id == habitId }
            )

            guard let habit = try modelContext.fetch(descriptor).first else {
                return false
            }

            // 오늘 날짜의 기록 확인
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            let hasRecord = habit.records.contains { record in
                calendar.isDate(record.date, inSameDayAs: today) && record.level != .none
            }

            return hasRecord
        } catch {
            print("❌ Error checking habit completion: \(error)")
            return false
        }
    }

    // MARK: - 습관 리마인더 취소
    func cancelHabitReminder(for habit: Habit) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [habit.id.uuidString])
        print("🗑️ Cancelled reminder for \(habit.title)")
    }

    // MARK: - 모든 예약된 알림 확인
    func listScheduledNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("📋 Scheduled notifications: \(requests.count)")
        for request in requests {
            print("  - \(request.identifier): \(request.content.title)")
        }
    }
}
