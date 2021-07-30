//
//  AnswerMessage.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 04/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation

class AnswerMessage : Message {

    init(sessionId: String,
         sdp: String,
         callInfo: TxCallInfo,
         callOptions: TxCallOptions) {

        var params = [String: Any]()
        var dialogParams = [String: Any]()
        // Merge callInfo into dialogParams
        callInfo.encode().forEach { (key, value) in dialogParams[key] = value }
        // Merge callOptions into dialogParams
        callOptions.encode().forEach { (key, value) in dialogParams[key] = value }

        // Get the SDK version
        let version = Bundle(for: Message.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let type = Message.CLIENT_TYPE
        params["User-Agent"] = type + "-" + version

        params["sessionId"] = sessionId
        params["sdp"] = sdp
        params["dialogParams"] = dialogParams
        super.init(params, method: .ANSWER)
    }
}
