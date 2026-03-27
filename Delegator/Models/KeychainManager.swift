//
//  KeychainManager.swift
//  Delegator
//

import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()

    private let service = "dev.delegator.ios"

    private enum Key: String {
        case gatewayURL = "gateway_url"
        case gatewayToken = "gateway_token"
        case hooksToken = "hooks_token"
    }

    // MARK: - Public API

    var gatewayURL: String? {
        get { read(key: .gatewayURL) }
        set {
            if let newValue {
                save(key: .gatewayURL, value: newValue)
            } else {
                delete(key: .gatewayURL)
            }
        }
    }

    var gatewayToken: String? {
        get { read(key: .gatewayToken) }
        set {
            if let newValue {
                save(key: .gatewayToken, value: newValue)
            } else {
                delete(key: .gatewayToken)
            }
        }
    }

    var hooksToken: String? {
        get { read(key: .hooksToken) }
        set {
            if let newValue {
                save(key: .hooksToken, value: newValue)
            } else {
                delete(key: .hooksToken)
            }
        }
    }

    var hasCredentials: Bool {
        gatewayURL != nil && gatewayToken != nil
    }

    func clearAll() {
        delete(key: .gatewayURL)
        delete(key: .gatewayToken)
        delete(key: .hooksToken)
    }

    // MARK: - Private

    private func save(key: Key, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func read(key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        SecItemDelete(query as CFDictionary)
    }
}
