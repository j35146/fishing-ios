import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var totalTrips: Int = 0
    @Published var totalCatches: Int = 0

    init() {
        // 从 UserDefaults 读取登录时保存的用户名
        username = UserDefaults.standard.string(forKey: "current_username") ?? "钓友"
        // 从 CoreData 读取本地统计（快速展示，无需 API）
        totalTrips = CoreDataManager.shared.fetchTrips().count
        totalCatches = CoreDataManager.shared.fetchAllCatches().count
    }

    func logout() {
        AuthManager.shared.logout()
    }
}
