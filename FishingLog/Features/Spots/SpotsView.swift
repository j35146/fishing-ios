import SwiftUI

struct SpotsView: View {
    @StateObject private var vm = SpotsViewModel()
    @State private var showNewSpot = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    // 地图/列表切换
                    Picker("视图", selection: $vm.displayMode) {
                        Text("地图").tag(SpotsViewModel.DisplayMode.map)
                        Text("列表").tag(SpotsViewModel.DisplayMode.list)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, FLMetrics.horizontalPadding)
                    .padding(.vertical, 8)

                    if vm.displayMode == .map {
                        SpotMapView(spots: vm.spots, userLocation: vm.userLocation)
                            .ignoresSafeArea(edges: .bottom)
                    } else {
                        SpotListView(vm: vm)
                    }
                }
            }
            .navigationTitle("钓点")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewSpot = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.primaryGold)
                    }
                }
            }
            .sheet(isPresented: $showNewSpot) {
                NewSpotView(vm: vm)
            }
        }
        .task { await vm.refresh() }
    }
}
