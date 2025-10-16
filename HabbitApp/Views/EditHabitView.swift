import SwiftUI
import SwiftData

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    let habit: Habit
    let viewModel: HabitViewModel
    
    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var selectedColor: String = "FF6B4A"
    @State private var selectedEmoji: String = "⭐️"

    // 각 레벨별 항목들
    @State private var miniItems: [String] = []
    @State private var moreItems: [String] = []
    @State private var maxItems: [String] = []

    // 리마인더 설정
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    let availableEmojis = [
        "⭐️", "🔥", "💪", "📚", "🏃‍♂️", "💧",
        "🎯", "🌟", "💎", "🚀", "🎨", "🎵",
        "🍎", "💡", "🎪", "🌈", "🎭", "🎨",
        "🏆", "💫", "🎊", "🎉", "✨", "🎈"
    ]
    
    let availableColors = [
        ("FF6B4A", "오렌지"),
        ("4CAF50", "그린"),
        ("2196F3", "블루"),
        ("9C27B0", "퍼플"),
        ("FF9800", "앰버"),
        ("00BCD4", "시안"),
        ("E91E63", "핑크"),
        ("607D8B", "블루그레이")
    ]
    
    var isFormValid: Bool {
        !title.isEmpty && !miniItems.isEmpty && !moreItems.isEmpty && !maxItems.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 이모지 선택
                        VStack(alignment: .leading, spacing: 12) {
                            Text("습관 이모지")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(availableEmojis, id: \.self) { emoji in
                                    EmojiButton(
                                        emoji: emoji,
                                        isSelected: selectedEmoji == emoji,
                                        action: { selectedEmoji = emoji }
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(.white.opacity(0.05))
                        .cornerRadius(16)
                        
                        // 색상 선택
                        VStack(alignment: .leading, spacing: 12) {
                            Text("습관 색상")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                                ForEach(availableColors, id: \.0) { colorHex, colorName in
                                    ColorButton(
                                        colorHex: colorHex,
                                        isSelected: selectedColor == colorHex,
                                        action: { selectedColor = colorHex }
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(.white.opacity(0.05))
                        .cornerRadius(16)
                        
                        // 습관 정보
                        VStack(alignment: .leading, spacing: 16) {
                            Text("습관 이름")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("예: 스페인어 학습", text: $title)
                                .textFieldStyle(DarkTextFieldStyle())
                        }
                        .padding()
                        .background(.white.opacity(0.05))
                        .cornerRadius(16)
                        
                        // 시작일
                        VStack(alignment: .leading, spacing: 12) {
                            Text("시작일")
                                .font(.headline)
                                .foregroundColor(.white)

                            DatePicker(
                                "시작일",
                                selection: $startDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                            .labelsHidden()
                        }
                        .padding()
                        .background(.white.opacity(0.05))
                        .cornerRadius(16)

                        // 리마인더 설정
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("일일 리마인더")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Spacer()

                                Toggle("", isOn: $reminderEnabled)
                                    .labelsHidden()
                            }

                            if reminderEnabled {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("알림 시간")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)

                                    DatePicker(
                                        "알림 시간",
                                        selection: $reminderTime,
                                        displayedComponents: .hourAndMinute
                                    )
                                    .datePickerStyle(.wheel)
                                    .colorScheme(.dark)
                                    .labelsHidden()
                                }
                            }
                        }
                        .padding()
                        .background(.white.opacity(0.05))
                        .cornerRadius(16)

                        // 각 레벨별 실천 항목
                        VStack(alignment: .leading, spacing: 16) {
                            Text("각 레벨별 실천 항목")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("매일 하나의 레벨을 선택하고 완료한 항목을 체크합니다")
                                .font(.caption)
                                .foregroundColor(.gray)

                            // MINI 항목들
                            ItemSection(
                                title: "MINI 미니",
                                items: $miniItems,
                                color: Color(hex: "B8E6D5")
                            )

                            // MORE 항목들
                            ItemSection(
                                title: "MORE 모어",
                                items: $moreItems,
                                color: Color(hex: "7DB3E8")
                            )

                            // MAX 항목들
                            ItemSection(
                                title: "MAX 맥스",
                                items: $maxItems,
                                color: Color(hex: "B48FD9")
                            )
                        }
                        .padding()
                        .background(.white.opacity(0.05))
                        .cornerRadius(16)
                    }
                    .padding()
                }
            }
            .navigationTitle("습관 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        updateHabit()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? Color(hex: selectedColor) : .gray)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            loadHabitData()
        }
    }
    
    private func loadHabitData() {
        title = habit.title
        startDate = habit.startDate
        selectedColor = habit.colorHex
        selectedEmoji = habit.emoji
        miniItems = habit.miniItems
        moreItems = habit.moreItems
        maxItems = habit.maxItems
        reminderEnabled = habit.reminderEnabled
        reminderTime = habit.reminderTime ?? Date()
    }
    
    private func updateHabit() {
        print("🔵 updateHabit() 호출됨")
        print("   - title: \(title)")
        print("   - emoji: \(selectedEmoji)")
        print("   - miniItems: \(miniItems)")
        print("   - moreItems: \(moreItems)")
        print("   - maxItems: \(maxItems)")
        print("   - reminderEnabled: \(reminderEnabled)")

        viewModel.updateHabit(
            habit,
            title: title,
            emoji: selectedEmoji,
            colorHex: selectedColor,
            startDate: startDate,
            miniItems: miniItems,
            moreItems: moreItems,
            maxItems: maxItems,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderEnabled ? reminderTime : nil
        )

        print("🔵 dismiss() 호출")
        dismiss()
    }
}


#Preview {
    let habit = Habit(
        title: "매일 운동하기",
        miniItems: ["산책 30분", "스트레칭 10분"],
        moreItems: ["헬스장 30분", "테니스 2시간"],
        maxItems: ["헬스 1시간", "테니스 2시간 이상"]
    )
    
    EditHabitView(
        habit: habit,
        viewModel: HabitViewModel(
            modelContext: ModelContext(
                try! ModelContainer(for: Habit.self, DailyRecord.self)
            )
        )
    )
}
