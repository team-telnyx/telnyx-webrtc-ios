//
//  AnswerMessage.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 04/03/2021.
//

import Foundation

class AnswerMessage : Message {

    init(sessionId: String,
         sdp: String,
         callInfo: TxCallInfo,
         callOptions: TxCallOptions) {

        var params = [String: Any]()
        var dialogParams = [String: Any]()
        dialogParams["callID"] = callInfo.callId.uuidString.lowercased()
        dialogParams["remote_caller_id_name"] = callOptions.remoteCallerName
        dialogParams["caller_id_name"] = callInfo.callerName
        dialogParams["caller_id_number"] = callOptions.remoteCallerNumber
        dialogParams["audio"] = callOptions.audio
        dialogParams["video"] = callOptions.video
        dialogParams["useStereo"] = callOptions.useStereo
        dialogParams["attach"] = callOptions.attach
        dialogParams["screenShare"] = callOptions.screenShare
        dialogParams["userVariables"] = callOptions.userVariables

        params["sessionId"] = sessionId
        params["sdp"] = sdp
        params["dialogParams"] = dialogParams
        super.init(params, method: .ANSWER)
    }
}
