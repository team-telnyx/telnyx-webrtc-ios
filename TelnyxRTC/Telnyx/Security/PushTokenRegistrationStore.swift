//
//  PushTokenRegistrationStore.swift
//  TelnyxRTC
//
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import Foundation
import Security

/// The last push registration this device logged in with.
struct StoredPushTokenRegistration: Codable, Equatable {
    let token: String
    let provider: String?
    let environment: String
    /// `sip:<user>` for SIP logins. All JWT logins share one value, because a JWT
    /// has no guaranteed stable user ID and can be refreshed for the same user.
    let accountKey: String
    /// Signaling server host, so development and production are never mixed.
    let server: String
}

extension StoredPushTokenRegistration {
    // The same default `LoginMessage` uses. Storing the result matters because a later build
    // type could otherwise send `disable_push` for the wrong environment.
    #if DEBUG
    private static let defaultEnvironment = PushEnvironment.debug
    #else
    private static let defaultEnvironment = PushEnvironment.production
    #endif

    /// Returns `nil` if the config has no push token or no login identity.
    init?(config: TxConfig, signalingServer: URL) {
        guard let token = config.pushNotificationConfig?.pushDeviceToken, !token.isEmpty,
              let accountKey = config.sipUser.map({ "sip:\($0)" }) ?? config.token.map({ _ in "jwt" }) else {
            return nil
        }
        self.init(token: token,
                  provider: config.pushNotificationConfig?.pushNotificationProvider,
                  environment: (config.pushEnvironment ?? Self.defaultEnvironment).rawValue,
                  accountKey: accountKey,
                  // Host only: push metadata can add query items to the URL.
                  server: signalingServer.host ?? signalingServer.absoluteString)
    }
}

protocol PushTokenRegistrationStoring {
    func load() -> StoredPushTokenRegistration?
    func save(_ registration: StoredPushTokenRegistration)
}

/// Keeps the last registration in a device-only Keychain item.
///
/// `AfterFirstUnlockThisDeviceOnly` keeps it out of backups, so restoring a backup onto
/// another phone can't make that phone disable the original phone's token. A failed read
/// or write only means a missed cleanup, so errors are not passed to the caller.
final class KeychainPushTokenRegistrationStore: PushTokenRegistrationStoring {
    private let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "com.telnyx.webrtc.push-token-registration.\(Bundle.main.bundleIdentifier ?? "default")",
        kSecAttrAccount as String: "last-registration-v1"
    ]

    func load() -> StoredPushTokenRegistration? {
        var lookup = query
        lookup[kSecReturnData as String] = true

        var item: CFTypeRef?
        guard SecItemCopyMatching(lookup as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(StoredPushTokenRegistration.self, from: data)
    }

    func save(_ registration: StoredPushTokenRegistration) {
        guard let data = try? JSONEncoder().encode(registration) else { return }

        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(item as CFDictionary, nil)
        if status != errSecSuccess {
            Logger.log.w(message: "KeychainPushTokenRegistrationStore:: save failed: \(status)")
        }
    }
}
