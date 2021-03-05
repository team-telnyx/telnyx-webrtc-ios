//
//  TxCallOptions.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 03/03/2021.
//

import Foundation

struct TxCallOptions {
    // Required
    var  destinationNumber: String?

    // Optional
    var remoteCallerName: String = "Outbound Call"
    var remoteCallerNumber: String?

    var audio: Bool = true
    var video: Bool = true
    var attach: Bool = false
    var useStereo: Bool = false
    var screenShare: Bool = false
    var userVariables: [String: Any]?
}