import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()
    private let tokenKey = "com.jiangfeng.fishinglog.token"
    private let udKey = "fl_auth_token"

    // 内存缓存
    private var cachedToken: String?

    func saveToken(_ token: String) {
        cachedToken = token
        // UserDefaults 持久化（Keychain 在无签名环境可能不可靠）
        UserDefaults.standard.set(token, forKey: udKey)
        // Keychain 同步写入
        let data = token.data(using: .utf8)!
        let deleteQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenKey
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        let addQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenKey,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    func getToken() -> String? {
        if let cachedToken { return cachedToken }
        // 先尝试 Keychain
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenKey,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data,
           let token = String(data: data, encoding: .utf8) {
            cachedToken = token
            return token
        }
        // Keychain 失败，回退 UserDefaults
        if let token = UserDefaults.standard.string(forKey: udKey) {
            cachedToken = token
            return token
        }
        return nil
    }

    func deleteToken() {
        cachedToken = nil
        UserDefaults.standard.removeObject(forKey: udKey)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenKey
        ]
        SecItemDelete(query as CFDictionary)
    }
}
