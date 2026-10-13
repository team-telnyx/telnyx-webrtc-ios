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
    /// Single source of truth for the mobile SDK library name emitted on every
    /// covered signaling message. Mirrors the cross-SDK "Commons Lib Usage
    /// Telemetry" spec (see VSDK-764): backend telemetry keys off
    /// `mobile_sdk_name` + `mobile_sdk_version`, independent of the legacy
    /// `User-Agent` string.
    internal static let MOBILE_SDK_NAME = "ios"

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
    /// `Message.USER_AGENT`.
    internal static func mobileSdkIdentity() -> [String: String] {
        return [
            "mobile_sdk_name": MOBILE_SDK_NAME,
            "mobile_sdk_version": SDK_VERSION,
        ]
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
