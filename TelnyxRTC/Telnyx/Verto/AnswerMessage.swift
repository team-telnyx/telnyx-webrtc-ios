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
         callOptions: TxCallOptions,
         customHeaders:[String:String] = [:]) {

        var params = [String: Any]()
        var dialogParams = [String: Any]()
        var xHeaders = [Any]()
        // Merge callInfo into dialogParams
        callInfo.encode().forEach { (key, value) in dialogParams[key] = value }
        // Merge callOptions into dialogParams
        callOptions.encode().forEach { (key, value) in dialogParams[key] = value }

        params["User-Agent"] = Message.USER_AGENT

        params["sessionId"] = sessionId
        params["sdp"] = sdp
        if(!customHeaders.isEmpty){
            customHeaders.keys.forEach { key in
                var header = [String:String]()
                header["name"] = key
                header["value"] = customHeaders[key]
                xHeaders.append(header)
            }
            dialogParams["custom_headers"] = xHeaders
        }
        params["dialogParams"] = dialogParams
        super.init(params, method: .ANSWER)
    }
}
