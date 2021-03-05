//
//  ModifyMessage.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 05/03/2021.
//

import Foundation

enum ModifyAction : String {
    case HOLD = "hold"
    case UNHOLD = "unhold"
    case TOGGLE_HOLD = "toggleHold"
}

class ModifyMessage : Message {

    init(sessionId: String, callId: String, action: ModifyAction) {
        var params = [String: Any]()
        var dialogParams = [String: Any]()
        dialogParams["callID"] = callId.lowercased()

        params["sessionId"] = sessionId
        params["action"] = action.rawValue
        params["dialogParams"] = dialogParams

        super.init(params, method: .MODIFY)
    }
}
