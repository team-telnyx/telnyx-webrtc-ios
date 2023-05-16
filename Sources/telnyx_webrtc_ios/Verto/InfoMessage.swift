//
//  InfoMessage.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 20/05/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

class InfoMessage : Message {

    init(sessionId: String,
         dtmf: String,
         callInfo: TxCallInfo,
         callOptions: TxCallOptions) {
        var params = [String: Any]()
        params["sessid"] = sessionId
        params["dtmf"] = dtmf

        var dialogParams = [String: Any]()
        // Merge callInfo into dialogParams
        callInfo.encode().forEach { (key, value) in dialogParams[key] = value }
        // Merge callOptions into dialogParams
        callOptions.encode().forEach { (key, value) in dialogParams[key] = value }

        params["dialogParams"] = dialogParams
        super.init(params, method: .INFO)
    }
}
