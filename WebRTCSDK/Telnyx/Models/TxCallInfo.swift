//
//  TxCallInfo.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 03/03/2021.
//

import Foundation


/// `TxCallInfo` contains the required information of the current Call
public struct TxCallInfo {
    var callId: UUID
    var callerName:String?
    var callerNumber: String?
}
