import SwiftUI

struct TripsListView: View {
    @StateObject private var viewModel = TripsListViewModel()
    @State private var showNewTrip = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if viewModel.trips.isEmpty && !viewModel.isLoading {
                    EmptyTripsView { showNewTrip = true }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.trips, id: \.id) { trip in
                                NavigationLink(destination: TripDetailView(trip: trip)) {
                                    TripCardView(trip: trip)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, FLMetrics.horizontalPadding)
                        .padding(.top, 8)
                    }
                    .refreshable { await viewModel.refresh() }
                }
            }
            .navigationTitle("钓鱼志")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewTrip = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.primaryGold)
                    }
                }
            }
            .sheet(isPresented: $showNewTrip) {
                NewTripView { await viewModel.refresh() }
            }
            .task { viewModel.loadLocal(); await viewModel.refresh() }
        }
    }
}

// 空状态
struct EmptyTripsView: View {
    let onNew: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fish").font(.system(size: 64))
                .foregroundColor(.textSecondary.opacity(0.4))
            Text("还没有出行记录").font(.flHeadline).foregroundColor(.textSecondary)
            Text("点击下方按钮记录你的第一次出行").font(.flBody).foregroundColor(.textSecondary.opacity(0.7))
            FLPrimaryButton("立即新建", action: onNew).frame(width: 200)
        }
        .padding(.horizontal, 40)
    }
}
