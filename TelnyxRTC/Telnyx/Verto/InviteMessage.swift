//
//  InviteMessage.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 03/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation


class InviteMessage : Message {

    init(sessionId: String,
         sdp: String,
         callInfo: TxCallInfo,
         callOptions: TxCallOptions,
         customHeaders:[String:String] = [:]
    ) {
        var params = [String: Any]()
        var dialogParams = [String: Any]()
        var xHeaders = [Any]()
        dialogParams["callID"] = callInfo.callId.uuidString.lowercased()
        dialogParams["destination_number"] = callOptions.destinationNumber
        dialogParams["remote_caller_id_name"] = callOptions.remoteCallerName
        dialogParams["caller_id_name"] = callInfo.callerName
        dialogParams["caller_id_number"] = callInfo.callerNumber
        dialogParams["audio"] = callOptions.audio
        dialogParams["video"] = callOptions.video
        dialogParams["useStereo"] = callOptions.useStereo
        dialogParams["attach"] = callOptions.attach
        dialogParams["screenShare"] = callOptions.screenShare
        dialogParams["userVariables"] = callOptions.userVariables
        if(!customHeaders.isEmpty){
            customHeaders.keys.forEach { key in
                var header = [String:String]()
                header["name"] = key
                header["value"] = customHeaders[key]
                xHeaders.append(header)
            }
            dialogParams["custom_headers"] = xHeaders
        }
        if let clientState = callOptions.clientState {
            dialogParams["clientState"] = clientState
        }

        params["User-Agent"] = Message.USER_AGENT

        params["sessionId"] = sessionId
        params["sdp"] = sdp
        params["dialogParams"] = dialogParams

        super.init(params, method: .INVITE)
    }
}
