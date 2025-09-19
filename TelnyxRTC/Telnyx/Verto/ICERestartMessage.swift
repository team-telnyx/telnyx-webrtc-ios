//
//  ICERestartMessage.swift
//  TelnyxRTC
//
//  Created by Claude AI on 2024.
//  Copyright © 2024 Telnyx LLC. All rights reserved.
//

import Foundation

class ICERestartMessage : Message {
    
    init(sessionId: String, callId: String, sdp: String) {
        var params = [String: Any]()
        var dialogParams = [String: Any]()
        
        dialogParams["callID"] = callId.lowercased()
        
        params["sessionId"] = sessionId
        params["action"] = "updateMedia"
        params["sdp"] = sdp

        params["dialogParams"] = dialogParams
        
        super.init(params, method: .MODIFY)
    }
}
