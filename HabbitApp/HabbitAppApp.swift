import SwiftUI
import SwiftData
import UserNotifications

@main
struct HabbitAppApp: App {
    @Environment(\.modelContext) private var modelContext
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            HomeView()
                .onAppear {
                    checkAllHabitsCycles()
                }
        }
        .modelContainer(for: [Habit.self, DailyRecord.self, CycleHistory.self], inMemory: false, isAutosaveEnabled: true, isUndoEnabled: false)
    }

    /// 앱 시작 시 모든 습관의 사이클 상태 확인
    private func checkAllHabitsCycles() {
        Task {
            await MainActor.run {
                // ModelContainer를 통해 modelContext 가져오기
                let container = try? ModelContainer(for: Habit.self, DailyRecord.self, CycleHistory.self)
                guard let context = container?.mainContext else { return }

                let descriptor = FetchDescriptor<Habit>(
                    predicate: #Predicate { $0.isActive == true }
                )

                do {
                    let habits = try context.fetch(descriptor)
                    let viewModel = HabitViewModel(modelContext: context)

                    for habit in habits {
                        viewModel.checkAndUpdateCycleCompletion(for: habit)
                    }

                    print("✅ 모든 습관의 사이클 상태 확인 완료")
                } catch {
                    print("❌ 습관 사이클 확인 실패: \(error)")
                }
            }
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Notification delegate 설정
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// 앱이 포그라운드에 있을 때 알림이 도착하면 호출됨
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        let habitId = notification.request.identifier

        // 습관이 이미 완료되었는지 확인
        if isHabitCompletedToday(habitId: habitId) {
            print("⏭️ 습관이 이미 완료되어 알림을 표시하지 않습니다: \(habitId)")
            // 알림을 표시하지 않음
            completionHandler([])
        } else {
            print("🔔 습관 미완료, 알림 표시: \(habitId)")
            // 알림 표시 (배너, 사운드, 배지)
            completionHandler([.banner, .sound, .badge])
        }
    }

    /// 사용자가 알림을 탭했을 때 호출됨
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 알림 탭 시 처리 (필요시 구현)
        print("📱 사용자가 알림을 탭함: \(response.notification.request.identifier)")
        completionHandler()
    }

    // MARK: - Helper Methods

    /// 오늘 습관이 완료되었는지 확인
    private func isHabitCompletedToday(habitId: String) -> Bool {
        guard let habitUUID = UUID(uuidString: habitId) else {
            print("❌ 유효하지 않은 habit ID: \(habitId)")
            return false
        }

        do {
            // ModelContainer 생성
            let container = try ModelContainer(for: Habit.self, DailyRecord.self, CycleHistory.self)
            let context = container.mainContext

            // Habit 찾기
            let habitDescriptor = FetchDescriptor<Habit>(
                predicate: #Predicate<Habit> { habit in
                    habit.id == habitUUID
                }
            )

            guard let habit = try context.fetch(habitDescriptor).first else {
                print("❌ 습관을 찾을 수 없음: \(habitId)")
                return false
            }

            // 오늘 날짜 확인
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

            // 오늘 기록이 있는지 확인
            let todayRecord = habit.records.first { record in
                record.date >= today && record.date < tomorrow
            }

            // 기록이 있고 level이 none이 아니면 완료된 것으로 간주
            if let record = todayRecord, record.level != .none {
                print("✅ 오늘 습관 완료됨: \(habit.title), level: \(record.level)")
                return true
            }

            print("❌ 오늘 습관 미완료: \(habit.title)")
            return false

        } catch {
            print("❌ 습관 완료 여부 확인 실패: \(error)")
            return false
        }
    }
}
