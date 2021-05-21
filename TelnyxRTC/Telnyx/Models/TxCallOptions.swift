//
//  TxCallOptions.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 03/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation


/// 
struct TxCallOptions {
    // Required
    var  destinationNumber: String?

    // Optional
    var remoteCallerName: String = "Outbound Call"
    var remoteCallerNumber: String?

    /// Telnyx's Call Control client_state. Can be used with Connections with Advanced -> Events enabled.
    /// `clientState` string should be base64 encoded.
    var clientState: String?
    var audio: Bool = true
    var video: Bool = false
    var attach: Bool = false
    var useStereo: Bool = false
    var screenShare: Bool = false
    var userVariables: [String: Any]?

    func encode() -> [String : Any] {
        var dictionary = [String: Any]()
        dictionary["remote_caller_id_name"] = remoteCallerName
        dictionary["caller_id_number"] = remoteCallerNumber
        dictionary["audio"] = audio
        dictionary["video"] = video
        dictionary["useStereo"] = useStereo
        dictionary["attach"] = attach
        dictionary["screenShare"] = screenShare
        dictionary["userVariables"] = userVariables
        return dictionary
    }
}
