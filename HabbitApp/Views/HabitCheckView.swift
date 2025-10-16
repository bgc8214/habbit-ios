import SwiftUI
import SwiftData

struct HabitCheckView: View {
    let habit: Habit
    let viewModel: HabitViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLevel: CompletionLevel = .none
    @State private var selectedItems: [String] = []
    @State private var memo: String = ""
    @FocusState private var isMemoFocused: Bool
    
    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                colors: [Color(hex: habit.colorHex), Color(hex: habit.colorHex).opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 상단 헤더
                    HabitCheckHeader(habit: habit)
                    
                    // 레벨 선택 버튼들
                    LevelSelectionButtons(
                        selectedLevel: $selectedLevel,
                        selectedItems: $selectedItems,
                        habit: habit
                    )

                    // 해당 레벨의 항목들 선택
                    if selectedLevel != .none && selectedLevel != .skip {
                        ItemSelectionSection(
                            selectedLevel: selectedLevel,
                            habit: habit,
                            selectedItems: $selectedItems
                        )
                    }

                    // 메모 섹션
                    MemoSection(memo: $memo, isMemoFocused: $isMemoFocused)
                    
                    // 하단 버튼들
                    BottomActionButtons(
                        selectedLevel: selectedLevel,
                        selectedItems: selectedItems,
                        memo: memo,
                        habit: habit,
                        viewModel: viewModel,
                        dismiss: dismiss,
                        isMemoFocused: $isMemoFocused
                    )
                }
                .padding()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            // 키보드 외부 터치 시 키보드 숨김
            isMemoFocused = false
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("완료") {
                    isMemoFocused = false
                }
                .foregroundColor(.white)
            }
        }
    }
}

// MARK: - 상단 헤더
struct HabitCheckHeader: View {
    let habit: Habit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(getCurrentDate())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(getCurrentDay())일 째")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text("멋져요! 실천하느라 수고하셨어요!")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
    
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: Date())
    }
    
    private func getCurrentDay() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.startOfDay(for: habit.startDate)
        
        let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
        return daysSinceStart + 1
    }
}

// MARK: - 레벨 선택 버튼들
struct LevelSelectionButtons: View {
    @Binding var selectedLevel: CompletionLevel
    @Binding var selectedItems: [String]
    let habit: Habit
    
    var body: some View {
        HStack(spacing: 16) {
            HabitCheckLevelButton(
                level: .skip,
                title: "SKIP",
                isSelected: selectedLevel == .skip,
                action: { selectLevel(.skip) }
            )
            
            HabitCheckLevelButton(
                level: .mini,
                title: "MINI",
                isSelected: selectedLevel == .mini,
                action: { selectLevel(.mini) }
            )
            
            HabitCheckLevelButton(
                level: .more,
                title: "MORE",
                isSelected: selectedLevel == .more,
                action: { selectLevel(.more) }
            )
            
            HabitCheckLevelButton(
                level: .max,
                title: "MAX",
                isSelected: selectedLevel == .max,
                action: { selectLevel(.max) }
            )
        }
    }
    
    private func selectLevel(_ level: CompletionLevel) {
        selectedLevel = level
        selectedItems = [] // 레벨 변경 시 선택된 항목 초기화
    }
}

struct HabitCheckLevelButton: View {
    let level: CompletionLevel
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(buttonColor)
                        .frame(width: 50, height: 50) // 외부 원은 동일하게
                    
                    if level == .skip {
                        Text("-")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .fill(.white)
                            .frame(width: innerCircleSize, height: innerCircleSize) // 내부 원 크기만 조정
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var innerCircleSize: CGFloat {
        switch level {
        case .mini: return 8
        case .more: return 12
        case .max: return 16
        default: return 8
        }
    }
    
    private var buttonColor: Color {
        if isSelected {
            switch level {
            case .skip:
                return .gray
            case .mini:
                return .white.opacity(0.5)
            case .more:
                return .white.opacity(0.6)
            case .max:
                return .white
            case .none:
                return .gray
            }
        } else {
            return .gray.opacity(0.3)
        }
    }
}

// MARK: - 항목 선택 섹션
struct ItemSelectionSection: View {
    let selectedLevel: CompletionLevel
    let habit: Habit
    @Binding var selectedItems: [String]

    var availableItems: [String] {
        switch selectedLevel {
        case .mini:
            return habit.miniItems
        case .more:
            return habit.moreItems
        case .max:
            return habit.maxItems
        default:
            return []
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("완료한 항목을 선택하세요")
                .font(.headline)
                .foregroundColor(.white)

            if availableItems.isEmpty {
                Text("이 레벨에 등록된 항목이 없습니다")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
            } else {
                ForEach(availableItems, id: \.self) { item in
                    ItemCheckButton(
                        item: item,
                        isSelected: selectedItems.contains(item),
                        onTap: {
                            if selectedItems.contains(item) {
                                selectedItems.removeAll { $0 == item }
                            } else {
                                selectedItems.append(item)
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - 항목 체크 버튼
struct ItemCheckButton: View {
    let item: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .green : .white.opacity(0.5))

                Text(item)
                    .font(.body)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding()
            .background(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 메모 섹션
struct MemoSection: View {
    @Binding var memo: String
    @FocusState.Binding var isMemoFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("메모")
                .font(.headline)
                .foregroundColor(.white)

            ZStack(alignment: .topLeading) {
                // 플레이스홀더
                if memo.isEmpty {
                    Text("오늘의 기록을 남겨보세요...")
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $memo)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundColor(.white)
                    .colorScheme(.dark)
                    .focused($isMemoFocused)
            }
            .padding(8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - 하단 액션 버튼들
struct BottomActionButtons: View {
    let selectedLevel: CompletionLevel
    let selectedItems: [String]
    let memo: String
    let habit: Habit
    let viewModel: HabitViewModel
    let dismiss: DismissAction
    @FocusState.Binding var isMemoFocused: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                dismiss()
            }) {
                Text("취소")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                print("🔄 완료 버튼 터치됨!")
                print("   - selectedLevel: \(selectedLevel)")
                print("   - memo: \(memo)")
                print("   - selectedItems: \(selectedItems)")
                
                // 키보드 숨김
                isMemoFocused = false
                
                viewModel.completeHabitWithItems(
                    habit,
                    level: selectedLevel,
                    selectedItems: selectedItems,
                    memo: memo.isEmpty ? nil : memo,
                    date: Date()
                )
                dismiss()
            }) {
                Text(actionButtonText)
                    .font(.headline)
                    .foregroundColor((selectedLevel != .none || !memo.isEmpty) ? .black : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background((selectedLevel != .none || !memo.isEmpty) ? Color.white : Color.white.opacity(0.2))
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(selectedLevel == .none && memo.isEmpty)
        }
    }
    
    private var actionButtonText: String {
        if selectedLevel == .none && memo.isEmpty {
            return "실천 행동을 선택하거나 메모를 입력하세요"
        } else {
            return "완료"
        }
    }
}

#Preview {
    let habit = Habit(
        title: "매일 운동하기",
        miniItems: ["산책 30분", "스트레칭 10분"],
        moreItems: ["헬스장 30분", "테니스 2시간"],
        maxItems: ["헬스 1시간", "테니스 2시간 이상"]
    )
    
    NavigationStack {
        HabitCheckView(
            habit: habit,
            viewModel: HabitViewModel(
                modelContext: ModelContext(
                    try! ModelContainer(for: Habit.self, DailyRecord.self)
                )
            )
        )
    }
    .modelContainer(for: [Habit.self, DailyRecord.self], inMemory: true)
}
