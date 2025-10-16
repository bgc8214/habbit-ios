import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

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
        content.title = "습관 실천 시간이에요!"
        content.body = "\(habit.title) - 오늘의 목표를 달성해보세요"
        content.sound = .default
        content.badge = 1

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
            print("✅ Scheduled reminder for \(habit.title) at \(hour):\(minute)")
        } catch {
            print("❌ Failed to schedule reminder: \(error)")
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
