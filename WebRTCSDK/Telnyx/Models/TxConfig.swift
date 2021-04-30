//
//  TxConfig.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 03/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation

/// This structure is intended to used for Telnyx SDK configurations.
public struct TxConfig {
    
    // MARK: - Properties

    public internal(set) var sipUser: String?
    public internal(set) var password: String?
    public internal(set) var token: String?

    public internal(set) var ringBackTone: String?
    public internal(set) var ringtone: String?

    // MARK: - Initializers

    /// Constructor of the Telnyx SDK configuration: Login using sip user  and password.
    /// - Parameters:
    ///   - sipUser: sipUser the SIP user
    ///   - password: password the password of the SIP user.
    ///   - ringtone: (Optional) The audio file name to be played when receiving an incoming call. e.g.: "my-ringtone.mp3"
    ///   - ringBackTone: (Optional) The audio file to be played when calling. e.g.: "my-ringbacktone.mp3"
    ///   - logLevel: (Optional) Can select the verbosity level of the SDK logs. Is set to `.none` as default
    public init(sipUser: String, password: String, ringtone: String? = nil, ringBackTone: String? = nil, logLevel: LogLevel = .none) {
        self.sipUser = sipUser
        self.password = password
        self.ringBackTone = ringBackTone
        self.ringtone = ringtone
        Logger.log.verboseLevel = logLevel
    }

    /// Constructor of the Telnyx SDK configuration: Login using a token.
    /// - Parameters:
    ///   - token: Token generated from https://developers.telnyx.com/docs/v2/webrtc/quickstart
    ///   - ringtone: (Optional) The audio file name to be played when receiving an incoming call. e.g.: "my-ringtone.mp3"
    ///   - ringBackTone: (Optional) The audio file name to be played when calling. e.g.: "my-ringbacktone.mp3"
    ///   - logLevel: (Optional) Can select the verbosity level of the SDK logs. Is set to `.none` as default
    public init(token: String, ringtone: String? = nil, ringBackTone: String? = nil, logLevel: LogLevel = .none) {
        self.token = token
        self.ringBackTone = ringBackTone
        self.ringtone = ringtone
        Logger.log.verboseLevel = logLevel
    }

    // MARK: - Methods

    /// Validate if TxConfig parameters are valid
    /// - Throws: Throws TxConfig parameters errors
    public func validateParams() throws {
        Logger.log.i(message: "TxConfig :: validateParams()")
        //Check if user has entered username and password parameters
        if let password = self.password,
           let user = self.sipUser {
            if (password.isEmpty && user.isEmpty) {
                throw TxError.clientConfigurationFailed(reason: .userNameAndPasswordAreRequired)
            }
            if (password.isEmpty) {
                throw TxError.clientConfigurationFailed(reason: .passwordIsRequired)
            }
            if (user.isEmpty) {
                throw TxError.clientConfigurationFailed(reason: .userNameIsRequired)
            }
        } else {
            //check if user has entered token as login
            if let token = self.token,
               token.isEmpty {
                throw TxError.clientConfigurationFailed(reason: .tokenIsRequired)
            }
        }
    }
}
