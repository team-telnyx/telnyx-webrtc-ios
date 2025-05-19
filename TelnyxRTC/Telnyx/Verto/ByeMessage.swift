//
//  ByeMessage.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 04/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation

/// Cause codes for call termination based on Telnyx's troubleshooting guide
/// https://support.telnyx.com/en/articles/5025298-troubleshooting-call-completion
enum CauseCode : Int {
    // General Hangup Reasons
    case NORMAL_CLEARING = 16
    case USER_BUSY = 17
    case CALL_REJECTED = 21
    case UNALLOCATED_NUMBER = 1
    case INCOMPATIBLE_DESTINATION = 88
    case MANAGER_REQUEST = 16
    
    // Inbound Hangup Reasons
    case RECOVERY_ON_TIMER_EXPIRE = 102
    case MANDATORY_IE_MISSING = 96
    case PROGRESS_TIMEOUT = 16
    case ALLOTTED_TIMEOUT = 602
    
    // Outbound Hangup Reasons
    case NORMAL_TEMPORARY_FAILURE = 41
    
    // Legacy codes
    case INVALID_GATEWAY = 608
    case ORIGINATOR_CANCEL = 487
}

class ByeMessage : Message {
        
    init(sessionId: String, callId: String, causeCode: CauseCode, sipCode: Int? = nil, sipReason: String? = nil) {
        var params = [String: Any]()
        var dialogParams = [String: Any]()
        
        dialogParams["callID"] = callId.lowercased()
        
        params["sessId"] = sessionId
        params["causeCode"] = causeCode.rawValue
        params["cause"] = ByeMessage.getCauseFromCode(causeCode: causeCode)
        
        // Add SIP code and reason if provided
        if let sipCode = sipCode {
            params["sipCode"] = sipCode
        }
        
        if let sipReason = sipReason {
            params["sipReason"] = sipReason
        }
        
        params["dialogParams"] = dialogParams

        super.init(params, method: .BYE)
    }
    
    private static func getCauseFromCode(causeCode: CauseCode) -> String {
        switch(causeCode) {
        case .USER_BUSY: return "USER_BUSY"
        case .NORMAL_CLEARING: return "NORMAL_CLEARING"
        case .CALL_REJECTED: return "CALL_REJECTED"
        case .UNALLOCATED_NUMBER: return "UNALLOCATED_NUMBER"
        case .INCOMPATIBLE_DESTINATION: return "INCOMPATIBLE_DESTINATION"
        case .MANAGER_REQUEST: return "MANAGER_REQUEST"
        case .RECOVERY_ON_TIMER_EXPIRE: return "RECOVERY_ON_TIMER_EXPIRE"
        case .MANDATORY_IE_MISSING: return "MANDATORY_IE_MISSING"
        case .PROGRESS_TIMEOUT: return "PROGRESS_TIMEOUT"
        case .ALLOTTED_TIMEOUT: return "ALLOTTED_TIMEOUT"
        case .NORMAL_TEMPORARY_FAILURE: return "NORMAL_TEMPORARY_FAILURE"
        case .INVALID_GATEWAY: return "INVALID_GATEWAY"
        case .ORIGINATOR_CANCEL: return "ORIGINATOR_CANCEL"
        }
    }
}
