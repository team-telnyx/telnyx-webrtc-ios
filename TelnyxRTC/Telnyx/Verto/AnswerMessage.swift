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
        // Merge callInfo into dialogParams
        callInfo.encode().forEach { (key, value) in dialogParams[key] = value }
        // Merge callOptions into dialogParams
        callOptions.encode().forEach { (key, value) in dialogParams[key] = value }

        params["User-Agent"] = Message.USER_AGENT

        params["sessionId"] = sessionId
        params["sdp"] = sdp
        if(!customHeaders.isEmpty){
            dialogParams["custom_headers"] = appendCustomHeaders(customHeaders: customHeaders)
        }
        params["dialogParams"] = dialogParams
        super.init(params, method: .ANSWER)
    }
}
