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
    internal static let CLIENT_TYPE = "iOS"
    internal static let SDK_VERSION = "2.4.0"
    internal static var USER_AGENT: String {
        get {
            let type = Message.CLIENT_TYPE
            let version = Message.SDK_VERSION
            return type + "-" + version
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
