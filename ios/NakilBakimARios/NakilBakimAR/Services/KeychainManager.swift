import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()
    private init() {}

    func saveToken(_ token: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "nakilbakimar_access_token",
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "nakilbakimar_access_token"
        ]
        SecItemDelete(query as CFDictionary)
    }
}
