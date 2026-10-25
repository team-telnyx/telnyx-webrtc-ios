//
//  Message.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 03/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation


private let PROTOCOL_VERSION: String = "2.0"

class Message {
    /// Single source of truth for the mobile SDK library name emitted on
    /// identity-bearing signaling messages. Mirrors the cross-SDK "Commons Lib Usage
    /// Telemetry" spec (see VSDK-764): backend telemetry keys off
    /// `mobile_sdk_name` + `mobile_sdk_version`, independent of the legacy
    /// `User-Agent` string. See VSDK-768 for the iOS-SDK side of this work.
    internal static let MOBILE_SDK_NAME = "webrtc-ios"

    /// JSON-RPC parameter key for the mobile SDK library name.
    internal static let MOBILE_SDK_NAME_KEY = "mobile_sdk_name"

    /// JSON-RPC parameter key for the mobile SDK version.
    internal static let MOBILE_SDK_VERSION_KEY = "mobile_sdk_version"

    internal static let CLIENT_TYPE = "iOS"
    internal static let SDK_VERSION = "4.2.2"
    internal static var USER_AGENT: String {
        get {
            return userAgent(enableMissedCallNotifications: false)
        }
    }

    internal static func userAgent(enableMissedCallNotifications: Bool) -> String {
        let type = Message.CLIENT_TYPE
        let version = Message.SDK_VERSION
        if enableMissedCallNotifications {
            return type + "-mpn-" + version
        }
        return type + "-" + version
    }

    /// Returns the canonical mobile-SDK identity pair (`mobile_sdk_name` +
    /// `mobile_sdk_version`) that every covered signaling message must
    /// serialize. Centralized so the values stay in lock-step with
    /// `MOBILE_SDK_NAME` / `SDK_VERSION` (single source of truth) and
    /// `Message.USER_AGENT`. VSDK-768 / VSDK-764.
    internal static func mobileSdkIdentity() -> [String: String] {
        return [
            MOBILE_SDK_NAME_KEY: MOBILE_SDK_NAME,
            MOBILE_SDK_VERSION_KEY: SDK_VERSION,
        ]
    }

    /// Methods whose backend contracts carry the public mobile SDK identity.
    /// Keep this list explicit so unrelated protocol messages (for example
    /// candidates, BYE, INFO, gateway state, and AI conversation messages)
    /// are not changed implicitly by the shared base initializer.
    private static func carriesMobileSdkIdentity(_ method: Method) -> Bool {
        switch method {
        case .LOGIN, .ANONYMOUS_LOGIN, .INVITE, .ANSWER, .ATTACH, .ATTACH_CALL, .DISABLE_PUSH:
            return true
        default:
            return false
        }
    }

    internal var jsonMessage: [String: Any] = [String: Any]()

    let jsonrpc = PROTOCOL_VERSION
    var id: String = UUID.init().uuidString.lowercased()
    var method: Method?
    var voiceSdkId : String? = nil
    var params: [String: Any]?
    var result: [String: Any]?
    var serverError: [String: Any]?

    init() {
        self.jsonMessage["jsonrpc"] = self.jsonrpc
        self.jsonMessage["id"] = self.id
    }

    init(_ params: [String: Any], method: Method) {
        // Independent mobile-SDK identity (VSDK-768 / VSDK-764 cross-SDK
        // telemetry spec). The explicit method allowlist keeps the shared
        // initializer from changing unrelated Verto message contracts while
        // ensuring login, invite, answer, reattach, anonymous-login,
        // disable-push, and attach-call emit
        // `mobile_sdk_name` + `mobile_sdk_version` as top-level params
        // without each subclass having to remember to wire it.
        //
        // The caller's `params` dict is intentionally NOT mutated; only
        // the local copy (and the stored `self.params` / `jsonMessage`)
        // gets the identity keys. This keeps the per-message init signatures
        // and observed behavior unchanged while guaranteeing coverage.
        var params = params
        if Message.carriesMobileSdkIdentity(method) {
            for (key, value) in Message.mobileSdkIdentity() {
                params[key] = value
            }
        }

        self.method = method
        self.jsonMessage["jsonrpc"] = self.jsonrpc
        self.jsonMessage["id"] = self.id
        self.jsonMessage["method"] = self.method?.rawValue
        self.jsonMessage["params"] = params
        self.params = params
        self.method = method

    }

    func encode() -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonMessage, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            Logger.log.e(message: "Message:: encode() error")
            return nil
        }
        Logger.log.i(message: "Message:: encode() " + jsonString)
        return jsonString
    }


    func decode(message: String) -> Message? {
        guard let data = message.data(using: .utf8) else { return nil }
        guard let jsonMessage =  try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]  else {
            Logger.log.e(message: "Message:: decode() error")
            return nil
        }

        self.id = jsonMessage["id"] as? String ?? ""
        self.method = Method(rawValue: jsonMessage["method"] as? String ?? "")
        self.result = jsonMessage["result"] as? [String: Any]
        self.params = jsonMessage["params"] as? [String: Any]
        self.serverError = jsonMessage["error"] as? [String: Any]
        self.voiceSdkId = jsonMessage["voice_sdk_id"] as? String
        self.jsonMessage = jsonMessage

        Logger.log.i(message: "Message:: decode() \(self.jsonMessage)")

        return self
    }
}
