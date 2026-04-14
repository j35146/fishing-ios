import SwiftUI

@main
struct FishingLogApp: App {
    // 注入全局依赖
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var coreDataManager = CoreDataManager.shared
    @StateObject private var syncManager = SyncManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(coreDataManager)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, newPhase in
                    // I64: 进入前台触发同步
                    if newPhase == .active && authManager.isLoggedIn {
                        syncManager.syncIfNeeded()
                    }
                }
        }
    }
}
