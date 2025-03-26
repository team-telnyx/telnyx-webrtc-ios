//
//  TxCallInfo.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 03/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation


/// `TxCallInfo` contains the required information of the current Call
public struct TxCallInfo {
    /// The UUID of the call - Used by SDK consumers and required for CallKit integration
    public internal(set) var callId: UUID
    /// The string representation of the call ID - Used internally for communication with the server
    /// This can be either a UUID string or a non-UUID format like "420009675_133898086@206.147.68.154"
    internal var callIdString: String
    /// The caller name of the call
    public internal(set) var callerName:String?
    /// The caller number of the call
    public internal(set) var callerNumber: String?
    
    /// Initialize with a UUID
    init(callId: UUID) {
        self.callId = callId
        self.callIdString = callId.uuidString.lowercased()
    }
    
    /// Initialize with a string callId
    /// If the string is a valid UUID, both callId and callIdString will use it
    /// If not, a new UUID will be generated for callId, and the original string will be kept in callIdString
    init(callIdString: String) {
        if let uuid = UUID(uuidString: callIdString) {
            self.callId = uuid
            self.callIdString = callIdString.lowercased()
        } else {
            self.callId = UUID()
            self.callIdString = callIdString
        }
    }

    func encode() -> [String : Any] {
        var dictionary = [String : Any]()
        dictionary["callID"] = callIdString
        dictionary["caller_id_name"] = callerName ?? ""
        dictionary["caller_id_number"] = callerNumber ?? ""
        return dictionary
    }
}
