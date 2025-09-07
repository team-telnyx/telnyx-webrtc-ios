//
//  RingingAckMessage.swift
//  TelnyxRTC
//
//  Created by AI SWE Agent on 29/07/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation

/// Message class for handling ringing acknowledgment messages
/// This is used to acknowledge that a ringing notification has been received
class RingingAckMessage: Message {
    
    /// Initialize a ringing acknowledgment message
    /// - Parameters:
    ///   - callId: The call ID to acknowledge
    ///   - sessionId: The session ID for the acknowledgment
    init(callId: String, sessionId: String) {
        var params = [String: Any]()
        params["callID"] = callId
        params["sessid"] = sessionId
        
        super.init(params, method: .RINGING_ACK)
    }
}