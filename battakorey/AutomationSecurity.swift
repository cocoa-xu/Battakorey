import Foundation
import Security

struct AutomationCredential: Codable, Equatable {
    let clientID: String
    let secret: String
}

protocol AutomationCredentialStoring {
    func loadCredential() throws -> AutomationCredential?
    func saveCredential(_ credential: AutomationCredential) throws
}

struct KeychainAutomationCredentialStore: AutomationCredentialStoring {
    private let service = "moe.uwucocoa.battakorey.automation"
    private let account = "primary-client"

    func loadCredential() throws -> AutomationCredential? {
        var query = locator
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw AutomationSecurityError.keychain(status)
        }
        guard let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(AutomationCredential.self, from: data)
    }

    func saveCredential(_ credential: AutomationCredential) throws {
        let data = try JSONEncoder().encode(credential)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemUpdate(locator as CFDictionary, attributes as CFDictionary)
        if status == errSecSuccess { return }
        guard status == errSecItemNotFound else {
            throw AutomationSecurityError.keychain(status)
        }

        var item = locator
        attributes.forEach { item[$0.key] = $0.value }
        let addStatus = SecItemAdd(item as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw AutomationSecurityError.keychain(addStatus)
        }
    }

    private var locator: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: false,
            kSecUseDataProtectionKeychain as String: true
        ]
    }
}

enum AutomationSecurityError: LocalizedError {
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case let .keychain(status):
            "Could not access the automation credential in Keychain (\(status))."
        }
    }
}
