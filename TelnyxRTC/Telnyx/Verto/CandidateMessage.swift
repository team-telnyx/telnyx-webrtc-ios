//
//  CandidateMessage.swift
//  TelnyxRTC
//
//  Created by AI SWE Agent on 21/10/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation

class CandidateMessage : Message {

    init(callId: String,
         sessionId: String,
         candidate: String,
         sdpMid: String,
         sdpMLineIndex: Int32) {

        var params = [String: Any]()
        var dialogParams = [String: Any]()

        dialogParams["callID"] = callId

        params["candidate"] = candidate
        params["sdpMid"] = sdpMid
        params["sdpMLineIndex"] = sdpMLineIndex
        params["dialogParams"] = dialogParams

        super.init(params, method: .CANDIDATE)
    }
}