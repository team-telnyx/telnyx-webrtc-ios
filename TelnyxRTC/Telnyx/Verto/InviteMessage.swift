//
//  InviteMessage.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 03/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation

class InviteMessage : Message {
        
    private static let CLIENT_TYPE = "iOS"

    init(sessionId: String,
         sdp: String,
         callInfo: TxCallInfo,
         callOptions: TxCallOptions) {
        var params = [String: Any]()
        var dialogParams = [String: Any]()

        // Get the SDK version
        let version = Bundle(for: InviteMessage.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let type = InviteMessage.CLIENT_TYPE
        params["User-Agent"] = type + "-" + version

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
        if let clientState = callOptions.clientState {
            dialogParams["clientState"] = clientState
        }

        params["sessionId"] = sessionId
        params["sdp"] = sdp
        params["dialogParams"] = dialogParams

        super.init(params, method: .INVITE)
    }
}
