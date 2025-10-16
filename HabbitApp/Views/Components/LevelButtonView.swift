import SwiftUI

struct LevelButtonView: View {
    let level: CompletionLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 50, height: 50)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                Text(level.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? foregroundColor : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var backgroundColor: Color {
        switch level {
        case .skip:
            return Color.gray.opacity(0.3)
        case .mini:
            return isSelected ? Color(hex: "8FD5C1") : Color(hex: "B8E6D5")
        case .more:
            return isSelected ? Color(hex: "5A9BD4") : Color(hex: "7DB3E8")
        case .max:
            return isSelected ? Color(hex: "9B6FC5") : Color(hex: "B48FD9")
        case .none:
            return Color.gray.opacity(0.3)
        }
    }
    
    private var foregroundColor: Color {
        switch level {
        case .skip:
            return Color.gray
        case .mini:
            return Color(hex: "8FD5C1")
        case .more:
            return Color(hex: "5A9BD4")
        case .max:
            return Color(hex: "9B6FC5")
        case .none:
            return Color.gray
        }
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    HStack(spacing: 20) {
        LevelButtonView(level: .mini, isSelected: false) {}
        LevelButtonView(level: .more, isSelected: true) {}
        LevelButtonView(level: .max, isSelected: false) {}
    }
    .padding()
}

