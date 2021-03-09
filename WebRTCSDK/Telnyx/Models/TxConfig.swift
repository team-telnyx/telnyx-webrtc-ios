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

    var ringBackTone: String?
    var ringtone: String?


    /// Constructor of the Telnyx SDK configuration: Login using sip user  and password.
    /// - Parameters:
    ///   - sipUser: sipUser the SIP user
    ///   - password: password the password of the SIP user.
    ///   - ringtone: (Optional) The audio file name to be played when receiving an incoming call. e.g.: "my-ringtone.mp3"
    ///   - ringBackTone: (Optional) The audio file to be played when calling. e.g.: "my-ringbacktone.mp3"
    public init(sipUser: String, password: String, ringtone: String? = nil, ringBackTone: String? = nil) {
        self.sipUser = sipUser
        self.password = password
        self.ringBackTone = ringBackTone
        self.ringtone = ringtone
    }

    /// Constructor of the Telnyx SDK configuration: Login using a token.
    /// - Parameters:
    ///   - token: Token generated from https://developers.telnyx.com/docs/v2/webrtc/quickstart
    ///   - ringtone: (Optional) The audio file name to be played when receiving an incoming call. e.g.: "my-ringtone.mp3"
    ///   - ringBackTone: (Optional) The audio file name to be played when calling. e.g.: "my-ringbacktone.mp3"
    public init(token: String, ringtone: String? = nil, ringBackTone: String? = nil) {
        self.token = token
        self.ringBackTone = ringBackTone
        self.ringtone = ringtone
    }
}
