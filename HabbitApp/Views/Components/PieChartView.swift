import SwiftUI
import Charts

struct PieChartView: View {
    let miniCount: Int
    let moreCount: Int
    let maxCount: Int
    let skipCount: Int
    let noneCount: Int

    var body: some View {
        VStack(spacing: 16) {
            // 파이차트
            ZStack {
                Chart {
                    if miniCount > 0 {
                        SectorMark(
                            angle: .value("Count", miniCount),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(Color(hex: "B8E6D5"))
                    }

                    if moreCount > 0 {
                        SectorMark(
                            angle: .value("Count", moreCount),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(Color(hex: "7DB3E8"))
                    }

                    if maxCount > 0 {
                        SectorMark(
                            angle: .value("Count", maxCount),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(Color(hex: "B48FD9"))
                    }

                    if skipCount > 0 {
                        SectorMark(
                            angle: .value("Count", skipCount),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(Color.gray.opacity(0.5))
                    }

                    if noneCount > 0 {
                        SectorMark(
                            angle: .value("Count", noneCount),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(Color.white.opacity(0.2))
                    }
                }
                .frame(height: 220)

                // 중앙 완료율
                VStack(spacing: 4) {
                    Text("\(completionRate)%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text("완료율")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            // 범례
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    LegendItem(color: Color(hex: "B8E6D5"), label: "MINI", count: miniCount)
                    LegendItem(color: Color(hex: "7DB3E8"), label: "MORE", count: moreCount)
                }

                HStack(spacing: 16) {
                    LegendItem(color: Color(hex: "B48FD9"), label: "MAX", count: maxCount)
                    LegendItem(color: Color.gray.opacity(0.5), label: "SKIP", count: skipCount)
                }

                if noneCount > 0 {
                    LegendItem(color: Color.white.opacity(0.2), label: "미완료", count: noneCount)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }

    private var totalCompleted: Int {
        miniCount + moreCount + maxCount
    }

    private var completionRate: Int {
        let rate = Double(totalCompleted) / 20.0 * 100.0
        return Int(rate.rounded())
    }
}

// MARK: - 범례 항목
struct LegendItem: View {
    let color: Color
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        PieChartView(
            miniCount: 5,
            moreCount: 7,
            maxCount: 3,
            skipCount: 2,
            noneCount: 3
        )
        .padding()
    }
}
