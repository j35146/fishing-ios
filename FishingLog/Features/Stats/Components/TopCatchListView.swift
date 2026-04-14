import SwiftUI

struct TopCatchListView: View {
    let catches: [TopCatch]

    var body: some View {
        if catches.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("最大渔获")
                    .font(.flHeadline)
                    .foregroundStyle(Color.textPrimary)

                ForEach(Array(catches.prefix(5).enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 12) {
                        // 排名
                        Text("\(index + 1)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.primaryGold)
                            .frame(width: 28)

                        // 鱼种名称
                        Text(item.fishSpecies)
                            .font(.flBody)
                            .foregroundStyle(Color.textPrimary)

                        Spacer()

                        // 重量 + 日期
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.1f kg", item.weightKg))
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Color.primaryGold)
                            Text(item.tripDate)
                                .font(.flCaption)
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                    .padding(.vertical, 6)

                    if index < min(catches.count, 5) - 1 {
                        Divider().background(Color.cardElevated)
                    }
                }
            }
            .padding(FLMetrics.cardPadding)
            .background(Color.cardBackground)
            .cornerRadius(FLMetrics.cornerRadius)
        }
    }
}
