import SwiftUI

struct SpotListView: View {
    @ObservedObject var vm: SpotsViewModel

    var body: some View {
        if vm.spots.isEmpty && !vm.isLoading {
            // 空状态
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "map")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.textTertiary)
                Text("暂无钓点")
                    .font(.flHeadline)
                    .foregroundStyle(Color.textSecondary)
                Text("点击右上角添加新钓点")
                    .font(.flCaption)
                    .foregroundStyle(Color.textTertiary)
                Spacer()
            }
        } else {
            List {
                ForEach(vm.spots) { spot in
                    SpotCardView(spot: spot) {
                        Task { await vm.deleteSpot(id: spot.id) }
                    }
                    .listRowBackground(Color.appBackground)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: FLMetrics.horizontalPadding,
                                             bottom: 4, trailing: FLMetrics.horizontalPadding))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .refreshable { await vm.refresh() }
        }
    }
}
