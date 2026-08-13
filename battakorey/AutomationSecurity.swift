import Foundation
import Security

protocol AutomationTokenStoring {
    func loadToken() throws -> String?
    func saveToken(_ token: String) throws
}

struct KeychainAutomationTokenStore: AutomationTokenStoring {
    private let service = "moe.uwucocoa.battakorey.automation"
    private let account = "bearer-token"

    func loadToken() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw AutomationSecurityError.keychain(status)
        }
        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8),
              !token.isEmpty else {
            throw AutomationSecurityError.invalidStoredToken
        }
        return token
    }

    func saveToken(_ token: String) throws {
        let lookup: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: Data(token.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemUpdate(lookup as CFDictionary, attributes as CFDictionary)
        if status == errSecSuccess { return }
        guard status == errSecItemNotFound else {
            throw AutomationSecurityError.keychain(status)
        }
        var item = lookup
        attributes.forEach { item[$0.key] = $0.value }
        let addStatus = SecItemAdd(item as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw AutomationSecurityError.keychain(addStatus)
        }
    }
}

enum AutomationSecurityError: LocalizedError {
    case randomGeneration(OSStatus)
    case keychain(OSStatus)
    case invalidStoredToken

    var errorDescription: String? {
        switch self {
        case let .randomGeneration(status):
            "Could not generate an access token (\(status))."
        case let .keychain(status):
            "Could not access the automation token in Keychain (\(status))."
        case .invalidStoredToken:
            "The automation token in Keychain is invalid."
        }
    }
}

enum AutomationToken {
    static func generate() throws -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            throw AutomationSecurityError.randomGeneration(status)
        }
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
