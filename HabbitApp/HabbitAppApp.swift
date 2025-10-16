import SwiftUI
import SwiftData

@main
struct HabbitAppApp: App {
    @Environment(\.modelContext) private var modelContext

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
