//
//  PushTokenRegistrationStore.swift
//  TelnyxRTC
//
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import Foundation
import Security

/// The APNs registration fields required to remove one exact push destination.
///
/// Keeping the environment and provider with the token is important because an
/// application can move between sandbox and production while the old token is
/// still accepted by APNs.
struct StoredPushTokenRegistration: Codable, Equatable {
    let token: String
    let provider: String
    let environment: String
}

struct StoredPushTokenAccountState: Codable, Equatable {
    var current: StoredPushTokenRegistration?
    var pendingCleanup: [StoredPushTokenRegistration]

    init(
        current: StoredPushTokenRegistration? = nil,
        pendingCleanup: [StoredPushTokenRegistration] = []
    ) {
        self.current = current
        self.pendingCleanup = pendingCleanup
    }
}

struct StoredPushTokenHistory: Codable, Equatable {
    var accounts: [String: StoredPushTokenAccountState]

    init(accounts: [String: StoredPushTokenAccountState] = [:]) {
        self.accounts = accounts
    }
}

protocol PushTokenRegistrationStoring {
    func load() throws -> StoredPushTokenHistory
    func save(_ history: StoredPushTokenHistory) throws
}

enum PushTokenRegistrationStoreError: Error {
    case keychain(OSStatus)
}

/// Persists push-token rotation state in a device-only Keychain item.
///
/// `AfterFirstUnlockThisDeviceOnly` allows background VoIP handling after the
/// first unlock while preventing this device's cleanup history from migrating
/// to a different physical device through a backup restore.
final class KeychainPushTokenRegistrationStore: PushTokenRegistrationStoring {
    private let service: String
    private let account: String

    init(
        service: String = "com.telnyx.webrtc.push-token-registration.\(Bundle.main.bundleIdentifier ?? "default")",
        account: String = "history-v1"
    ) {
        self.service = service
        self.account = account
    }

    func load() throws -> StoredPushTokenHistory {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return StoredPushTokenHistory()
        }

        guard status == errSecSuccess else {
            throw PushTokenRegistrationStoreError.keychain(status)
        }

        guard let data = item as? Data,
              let history = try? JSONDecoder().decode(StoredPushTokenHistory.self, from: data) else {
            // A schema or data corruption issue must not permanently block
            // login. Drop only this SDK-owned item and rebuild its best-effort
            // history from the next observed token.
            let deleteStatus = SecItemDelete(baseQuery as CFDictionary)
            guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
                throw PushTokenRegistrationStoreError.keychain(deleteStatus)
            }
            return StoredPushTokenHistory()
        }

        return history
    }

    func save(_ history: StoredPushTokenHistory) throws {
        let data = try JSONEncoder().encode(history)
        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )

        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw PushTokenRegistrationStoreError.keychain(updateStatus)
        }

        var addQuery = baseQuery
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw PushTokenRegistrationStoreError.keychain(addStatus)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

/// Maintains the last token observed for each SDK authentication scope and a
/// durable cleanup queue for tokens that were replaced.
final class PushTokenRegistrationTracker {
    private static let lock = NSLock()
    private let store: PushTokenRegistrationStoring

    init(store: PushTokenRegistrationStoring = KeychainPushTokenRegistrationStore()) {
        self.store = store
    }

    /// Records the current registration and returns stale registrations that
    /// should be disabled after the current login reaches REGED.
    func registrationsToCleanup(
        current: StoredPushTokenRegistration,
        accountKey: String
    ) throws -> [StoredPushTokenRegistration] {
        Self.lock.lock()
        defer { Self.lock.unlock() }

        var history = try store.load()
        var state = history.accounts[accountKey] ?? StoredPushTokenAccountState()

        if let previous = state.current, previous != current,
           !state.pendingCleanup.contains(previous) {
            state.pendingCleanup.append(previous)
        }

        state.current = current
        // Never attempt to disable the registration that is about to log in.
        state.pendingCleanup.removeAll { $0 == current }
        history.accounts[accountKey] = state
        try store.save(history)

        return state.pendingCleanup
    }

    /// Removes a stale registration only after the signaling server confirms
    /// that its targeted disable operation succeeded.
    func markCleanupSucceeded(
        _ registration: StoredPushTokenRegistration,
        accountKey: String
    ) throws {
        Self.lock.lock()
        defer { Self.lock.unlock() }

        var history = try store.load()
        guard var state = history.accounts[accountKey] else { return }

        state.pendingCleanup.removeAll { $0 == registration }
        history.accounts[accountKey] = state
        try store.save(history)
    }
}
