import Charts
import SwiftUI

struct SpeciesChartView: View {
    let species: [SpeciesItem]

    // 前5种 + 其他
    private var chartData: [SpeciesItem] {
        guard !species.isEmpty else { return [] }
        if species.count <= 5 { return species }
        let top5 = Array(species.prefix(5))
        let otherPercentage = species.dropFirst(5).reduce(0.0) { $0 + $1.percentage }
        let otherCount = species.dropFirst(5).reduce(0) { $0 + $1.count }
        let other = SpeciesItem(name: "其他", count: otherCount, percentage: otherPercentage)
        return top5 + [other]
    }

    private let colors: [Color] = [
        .primaryGold, .accentBlue, .green, .orange, .purple, .gray
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("鱼种分布")
                .font(.flHeadline)
                .foregroundStyle(Color.textPrimary)

            if chartData.isEmpty {
                HStack {
                    Spacer()
                    Text("暂无渔获记录")
                        .font(.flBody)
                        .foregroundStyle(Color.textTertiary)
                    Spacer()
                }
                .frame(height: 160)
            } else {
                HStack(alignment: .center, spacing: 16) {
                    // 饼图
                    Chart(chartData) { item in
                        SectorMark(
                            angle: .value("数量", item.count),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("鱼种", item.name))
                    }
                    .chartForegroundStyleScale(domain: chartData.map(\.name),
                                                range: Array(colors.prefix(chartData.count)))
                    .chartLegend(.hidden)
                    .frame(width: 140, height: 140)

                    // 图例
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(chartData.enumerated()), id: \.offset) { index, item in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(colors[index % colors.count])
                                    .frame(width: 8, height: 8)
                                Text(item.name)
                                    .font(.flCaption)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                Text(String(format: "%.0f%%", item.percentage))
                                    .font(.flCaption)
                                    .foregroundStyle(Color.textTertiary)
                            }
                        }
                    }
                }
            }
        }
        .padding(FLMetrics.cardPadding)
        .background(Color.cardBackground)
        .cornerRadius(FLMetrics.cornerRadius)
    }
}
