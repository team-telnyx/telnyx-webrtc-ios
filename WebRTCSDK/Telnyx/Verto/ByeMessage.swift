//
//  ByeMessage.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 04/03/2021.
//

import Foundation

enum CauseCode : Int {
    case USER_BUSY = 17
    case NORMAL_CLEARING = 16
    case INVALID_GATEWAY = 608
    case ORIGINATOR_CANCEL = 487
}

class ByeMessage : Message {
        
    init(sessionId: String, callId: String, causeCode: CauseCode) {
        var params = [String: Any]()
        var dialogParams = [String: Any]()
        
        dialogParams["callID"] = callId.lowercased()
        
        params["sessId"] = sessionId
        params["causeCode"] = causeCode.rawValue
        params["cause"] = ByeMessage.getCauseFromCode(causeCode: causeCode)
        params["dialogParams"] =  dialogParams

        super.init(params, method: .BYE)
    }
    
    private static func getCauseFromCode(causeCode: CauseCode) -> String {
        switch(causeCode) {
        case .USER_BUSY: return "USER_BUSY"
        default: return "NORMAL_CLEARING"
        }
    }
}
