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
    var token: String?


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

    /// Constructor of the Telnyx SDK configuration
    /// Login using a token.
    /// - Parameter token: Token generated from https://developers.telnyx.com/docs/v2/webrtc/quickstart
    public init(token: String) {
        self.token = token
    }
}
