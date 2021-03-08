//
//  TxConfig.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 03/03/2021.
//

import Foundation

/// This structure is intended to used for Telnyx SDK configurations.
public struct TxConfig {
    var sipUser: String?
    var password: String?


    /// Constructor of the Telnyx SDK configuration
    /// Login using sip user  and password.
    ///
    /// - Parameters:
    ///   - sipUser: sipUser the SIP user
    ///   - password: password the password of the SIP user.
    public init(sipUser: String, password: String) {
        self.sipUser = sipUser
        self.password = password
    }
}
