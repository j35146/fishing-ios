import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TripsListView()
                .tabItem { Label("日志", systemImage: "book.fill") }

            StatsView()
                .tabItem { Label("统计", systemImage: "chart.bar.fill") }

            GearListView()
                .tabItem { Label("装备", systemImage: "wrench.and.screwdriver.fill") }

            SpotsView()
                .tabItem { Label("钓点", systemImage: "map.fill") }

            ProfileView()
                .tabItem { Label("我的", systemImage: "person.fill") }
        }
        .tint(.primaryGold)
        .toolbarBackground(Color(hex: "#101c2e").opacity(0.9), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
