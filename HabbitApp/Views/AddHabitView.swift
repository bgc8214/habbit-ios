import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: HabitViewModel
    
    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var selectedColor: String = "FF6B4A" // 주황색 기본
    @State private var selectedEmoji: String = "⭐️" // 기본 이모지

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
            .navigationTitle("새 습관 추가")
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
                        saveHabit()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? Color(hex: selectedColor) : .gray)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private func saveHabit() {
        print("🔵 saveHabit() 호출됨")
        print("   - title: \(title)")
        print("   - miniItems: \(miniItems)")
        print("   - moreItems: \(moreItems)")
        print("   - maxItems: \(maxItems)")
        print("   - reminderEnabled: \(reminderEnabled)")

        let habit = viewModel.addHabitSimple(
            title: title,
            startDate: startDate,
            colorHex: selectedColor,
            miniItems: miniItems,
            moreItems: moreItems,
            maxItems: maxItems,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderEnabled ? reminderTime : nil,
            emoji: selectedEmoji
        )

        print("🔵 addHabitSimple 반환값: \(habit != nil ? "성공" : "실패")")

        // 리마인더 예약
        if reminderEnabled, let habit = habit {
            print("🔔 리마인더 예약 시작")
            Task {
                let granted = await NotificationManager.shared.requestAuthorization()
                if granted {
                    await NotificationManager.shared.scheduleHabitReminder(for: habit)
                }
            }
        }

        print("🔵 dismiss() 호출")
        dismiss()
    }
}

// MARK: - ItemSection 컴포넌트
struct ItemSection: View {
    let title: String
    @Binding var items: [String]
    let color: Color
    
    @State private var newItem: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            // 기존 항목들
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack {
                    Text(item)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Button(action: {
                        items.remove(at: index)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            
            // 새 항목 추가
            HStack {
                TextField("새 항목 추가", text: $newItem)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        addNewItem()
                    }
                
                Button(action: addNewItem) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                }
                .disabled(newItem.isEmpty)
            }
        }
    }
    
    private func addNewItem() {
        if !newItem.isEmpty {
            items.append(newItem)
            newItem = ""
        }
    }
}

struct EmojiButton: View {
    let emoji: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.clear)
                    .frame(width: 50, height: 50)
                
                Text(emoji)
                    .font(.title2)
                
                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 3)
                        .frame(width: 58, height: 58)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct ColorButton: View {
    let colorHex: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 50, height: 50)
                
                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 3)
                        .frame(width: 58, height: 58)
                    
                    Image(systemName: "checkmark")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct GoalInput: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 50, alignment: .leading)
            
            TextField(placeholder, text: $text, axis: .vertical)
                .textFieldStyle(DarkTextFieldStyle())
                .lineLimit(1...3)
        }
    }
}

struct DarkTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding()
            .background(.white.opacity(0.1))
            .cornerRadius(12)
            .foregroundColor(.white)
    }
}

#Preview {
    AddHabitView(viewModel: HabitViewModel(modelContext: ModelContext(try! ModelContainer(for: Habit.self, DailyRecord.self))))
}
