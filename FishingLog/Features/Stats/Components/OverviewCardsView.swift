import SwiftUI

struct OverviewCardsView: View {
    let overview: StatsOverview?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            StatCard(value: "\(overview?.totalTrips ?? 0)", label: "总出行")
            StatCard(value: "\(overview?.totalCatches ?? 0)", label: "总渔获")
            StatCard(value: "\(overview?.totalSpecies ?? 0)", label: "鱼种数")
            StatCard(value: String(format: "%.1f", overview?.totalWeightKg ?? 0), label: "总重量(kg)")
        }
    }
}

// 单个统计卡片
private struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        FLCard {
            VStack(spacing: 6) {
                Text(value)
                    .font(.flTitle)
                    .foregroundStyle(Color.primaryGold)
                Text(label)
                    .font(.flCaption)
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
