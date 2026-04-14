import SwiftUI

struct StatsView: View {
    @StateObject private var vm = StatsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                if vm.isLoading && vm.overview == nil {
                    ProgressView()
                        .tint(.accentBlue)
                } else if let error = vm.error, vm.overview == nil {
                    // 错误占位卡片
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.destructiveRed)
                        Text(error)
                            .font(.flBody)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                        Button {
                            Task { await vm.fetchAll() }
                        } label: {
                            Text("重试")
                                .font(.flHeadline)
                                .foregroundStyle(Color.primaryGold)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.cardBackground)
                                .cornerRadius(FLMetrics.cornerRadius)
                        }
                    }
                    .padding(.horizontal, FLMetrics.horizontalPadding)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            OverviewCardsView(overview: vm.overview)
                            SeasonalChartView(data: vm.seasonal, selectedYear: $vm.selectedYear)
                            SpeciesChartView(species: vm.species)
                            TopCatchListView(catches: vm.topCatches)
                        }
                        .padding(.horizontal, FLMetrics.horizontalPadding)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await vm.fetchAll() }
    }
}
