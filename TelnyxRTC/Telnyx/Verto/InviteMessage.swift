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
         customHeaders:[String:String] = [:],
         trickle: Bool = false
    ) {
        var params = [String: Any]()
        var dialogParams = [String: Any]()
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
            dialogParams["custom_headers"] = appendCustomHeaders(customHeaders: customHeaders)
        }
        if let clientState = callOptions.clientState {
            dialogParams["clientState"] = clientState
        }
        
        if let preferredCodecs = callOptions.preferredCodecs, !preferredCodecs.isEmpty {
            dialogParams["preferred_codecs"] = preferredCodecs.map { $0.toDictionary() }
        }

        params["User-Agent"] = Message.USER_AGENT

        params["sessionId"] = sessionId
        params["sdp"] = sdp
        params["dialogParams"] = dialogParams
        if trickle {
            params["trickle"] = true
        }

        super.init(params, method: .INVITE)
    }
}
