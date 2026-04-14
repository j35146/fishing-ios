import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()
    private let tokenKey = "com.jiangfeng.fishinglog.token"

    // 内存缓存：Keychain 在模拟器/无签名环境可能不可靠，用内存兜底
    private var cachedToken: String?

    func saveToken(_ token: String) {
        cachedToken = token

        let data = token.data(using: .utf8)!
        // 删除时只用 class + account 定位，不带 value
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
        // 优先返回内存缓存
        if let cachedToken { return cachedToken }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenKey,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else { return nil }
        cachedToken = token
        return token
    }

    func deleteToken() {
        cachedToken = nil
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenKey
        ]
        SecItemDelete(query as CFDictionary)
    }
}
