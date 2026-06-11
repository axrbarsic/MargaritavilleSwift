import Foundation
import Security

protocol SecretStore: Sendable {
    func readSecret(account: String) throws -> String?
    func saveSecret(_ secret: String, account: String) throws
    func deleteSecret(account: String) throws
}

struct KeychainSecretStore: SecretStore {
    enum StoreError: Error, Equatable {
        case unexpectedStatus(OSStatus)
    }

    private let service: String

    init(service: String = "com.alex.margaritaville.swift.secrets") {
        self.service = service
    }

    func readSecret(account: String) throws -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw StoreError.unexpectedStatus(status) }
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func saveSecret(_ secret: String, account: String) throws {
        let data = Data(secret.utf8)
        var query = baseQuery(account: account)
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            let update = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
            guard updateStatus == errSecSuccess else { throw StoreError.unexpectedStatus(updateStatus) }
            return
        }
        guard status == errSecItemNotFound else { throw StoreError.unexpectedStatus(status) }
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else { throw StoreError.unexpectedStatus(addStatus) }
    }

    func deleteSecret(account: String) throws {
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw StoreError.unexpectedStatus(status)
        }
    }

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
