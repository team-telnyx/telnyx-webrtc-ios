//
//  TxConfig.swift
//  TelnyxRTC
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
    public internal(set) var pushNotificationConfig: TxPushConfig?

    public internal(set) var ringBackTone: String?
    public internal(set) var ringtone: String?
    public internal(set) var autoReconnect: Bool

    // MARK: - Initializers

    /// Constructor of the Telnyx SDK configuration: Login using sip user  and password.
    /// - Parameters:
    ///   - sipUser: sipUser the SIP user
    ///   - password: password the password of the SIP user.
    ///   - pushDeviceToken: (Optional) the device push notification token. This is required to receive Inbound calls notifications.
    ///   - ringtone: (Optional) The audio file name to be played when receiving an incoming call. e.g.: "my-ringtone.mp3"
    ///   - ringBackTone: (Optional) The audio file to be played when calling. e.g.: "my-ringbacktone.mp3"
    ///   - autoReconnect: (Optional) Determine if the SDK has to re-connect automatically when detecting a gateway connection failure. This is set to`true` as default
    ///   - logLevel: (Optional) Can select the verbosity level of the SDK logs. Is set to `.none` as default
    public init(sipUser: String, password: String,
                pushDeviceToken: String? = nil,
                ringtone: String? = nil,
                ringBackTone: String? = nil,
                autoReconnect: Bool = true,
                logLevel: LogLevel = .none) {
        self.autoReconnect = autoReconnect
        self.sipUser = sipUser
        self.password = password
        if let pushToken = pushDeviceToken {
            //Create a notification configuration if there's an available a device push notification token
            pushNotificationConfig = TxPushConfig(pushDeviceToken: pushToken)
        }
        self.ringBackTone = ringBackTone
        self.ringtone = ringtone
        Logger.log.verboseLevel = logLevel
    }

    /// Constructor of the Telnyx SDK configuration: Login using a token.
    /// - Parameters:
    ///   - token: Token generated from https://developers.telnyx.com/docs/v2/webrtc/quickstart
    ///   - pushDeviceToken: (Optional) the device push notification token. This is required to receive Inbound calls notifications.
    ///   - ringtone: (Optional) The audio file name to be played when receiving an incoming call. e.g.: "my-ringtone.mp3"
    ///   - ringBackTone: (Optional) The audio file name to be played when calling. e.g.: "my-ringbacktone.mp3"
    ///   - logLevel: (Optional) Can select the verbosity level of the SDK logs. Is set to `.none` as default
    ///   - autoReconnect: (Optional) Determine if the SDK has to re-connect automatically when detecting a gateway connection failure. This is set to`true` as default
    public init(token: String,
                pushDeviceToken: String? = nil,
                ringtone: String? = nil,
                ringBackTone: String? = nil,
                autoReconnect: Bool = true,
                logLevel: LogLevel = .none) {
        self.autoReconnect = true
        self.token = token
        if let pushToken = pushDeviceToken {
            //Create a notification configuration if there's an available a device push notification token
            pushNotificationConfig = TxPushConfig(pushDeviceToken: pushToken)
        }
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
