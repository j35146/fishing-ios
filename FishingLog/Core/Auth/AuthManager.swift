import Foundation
import Combine

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var isLoggedIn: Bool = false

    private init() {
        // 启动时检查 Keychain 中是否有有效 token
        isLoggedIn = KeychainManager.shared.getToken() != nil
    }

    func login(username: String, password: String) async throws {
        let token = try await APIClient.shared.login(username: username, password: password)
        KeychainManager.shared.saveToken(token)
        // 保存用户名用于个人中心展示
        UserDefaults.standard.set(username, forKey: "current_username")
        isLoggedIn = true
    }

    func logout() {
        KeychainManager.shared.deleteToken()
        isLoggedIn = false
    }
}
