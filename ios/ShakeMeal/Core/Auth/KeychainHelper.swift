import Foundation
import Security

/// Thin wrapper around the iOS Keychain for securely storing string values.
enum KeychainHelper {

    private static let service = "com.shakemeal.app"

    // MARK: - Save

    @discardableResult
    static func save(_ value: String, forKey key: String) -> Bool {
        let data = Data(value.utf8)
        // Delete any existing item first so we can upsert cleanly.
        delete(forKey: key)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData:   data,
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Load

    static func load(forKey key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      key,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Delete

    @discardableResult
    static func delete(forKey key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
