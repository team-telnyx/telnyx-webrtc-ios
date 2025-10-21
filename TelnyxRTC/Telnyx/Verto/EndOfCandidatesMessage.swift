//
//  EndOfCandidatesMessage.swift
//  TelnyxRTC
//
//  Created by AI SWE Agent on 21/10/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation

class EndOfCandidatesMessage : Message {

    init(callId: String) {
        
        var params = [String: Any]()
        var dialogParams = [String: Any]()
        
        dialogParams["callID"] = callId
        
        params["dialogParams"] = dialogParams
        
        super.init(params, method: .END_OF_CANDIDATES)
    }
}