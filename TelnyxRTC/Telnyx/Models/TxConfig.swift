//
//  TxConfig.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 03/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation

public enum PushEnvironment: String {
    case production = "production"
    case debug = "debug"
}
/// This structure is intended to used for Telnyx SDK configurations.
public struct TxConfig {


    /// Default timeout value for reconnection attempts in seconds.
    /// After this period, if a call hasn't successfully reconnected, it will be terminated.
    public static let DEFAULT_TIMEOUT = 60.0

    // MARK: - Properties
    public internal(set) var sipUser: String?
    public internal(set) var password: String?
    public internal(set) var token: String?
    public internal(set) var pushNotificationConfig: TxPushConfig?

    public internal(set) var ringBackTone: String?
    public internal(set) var ringtone: String?
    public internal(set) var reconnectClient: Bool = true
    public internal(set) var pushEnvironment: PushEnvironment?
    
    /// Enables WebRTC communication statistics reporting to Telnyx servers.
    /// - Note: This flag is different from `logLevel`:
    ///   - `debug`: When enabled, sends WebRTC communication statistics to Telnyx servers for monitoring and debugging purposes.
    ///     See `WebRTCStatsReporter` class for details on the statistics collected.
    ///   - `logLevel`: Controls console log output in Xcode when running the app in debug mode.
    /// - Important: The `debug` flag is disabled by default to minimize data usage.
    public internal(set) var debug: Bool = false
    
    /// Controls whether the SDK should force TURN relay for peer connections.
    /// When enabled, the SDK will only use TURN relay candidates for ICE gathering,
    /// which prevents the "local network access" permission popup from appearing.
    /// - Note: Enabling this may affect the quality of calls when devices are on the same local network,
    ///         as all media will be relayed through TURN servers.
    /// - Important: This setting is disabled by default to maintain optimal call quality.
    public internal(set) var forceRelayCandidate: Bool = false
    
    /// Controls whether the SDK should deliver call quality metrics
    public internal(set) var enableQualityMetrics: Bool = false
    
    
    /// Maximum time (in seconds) the SDK will attempt to reconnect a call after network disruption.
    /// - If a call is successfully reconnected within this time, the call continues normally.
    /// - If reconnection fails after this timeout period, the call will be terminated and a `reconnectFailed` error will be triggered.
    /// - Default value is 60 seconds (defined by `DEFAULT_TIMEOUT`).
    /// - This timeout helps prevent calls from being stuck in a "reconnecting" state indefinitely.
    public internal(set) var reconnectTimeout: Double = DEFAULT_TIMEOUT
    
    /// Custom logger implementation for handling SDK logs
    /// If not provided, the default logger will be used
    public internal(set) var customLogger: TxLogger?

    // MARK: - Initializers

    /// Constructor for the Telnyx SDK configuration using SIP credentials.
    /// - Parameters:
    ///   - sipUser: The SIP username for authentication
    ///   - password: The password associated with the SIP user
    ///   - pushDeviceToken: (Optional) The device's push notification token, required for receiving inbound call notifications
    ///   - ringtone: (Optional) The audio file name to play for incoming calls (e.g., "my-ringtone.mp3")
    ///   - ringBackTone: (Optional) The audio file name to play while making outbound calls (e.g., "my-ringbacktone.mp3")
    ///   - logLevel: (Optional) The verbosity level for SDK logs (defaults to `.none`)
    ///   - customLogger: (Optional) Custom logger implementation for handling SDK logs. If not provided, the default logger will be used
    ///   - reconnectTimeOut: (Optional) Maximum time in seconds the SDK will attempt to reconnect a call after network disruption. Default is 60 seconds.
    public init(sipUser: String, password: String,
                pushDeviceToken: String? = nil,
                ringtone: String? = nil,
                ringBackTone: String? = nil,
                pushEnvironment: PushEnvironment? = nil,
                logLevel: LogLevel = .none,
                customLogger: TxLogger? = nil,
                reconnectClient: Bool = true,
                debug: Bool = false,
                forceRelayCandidate: Bool = false,
                enableQualityMetrics: Bool = false,
                reconnectTimeOut: Double = DEFAULT_TIMEOUT
    ) {
        self.sipUser = sipUser
        self.password = password
        if let pushToken = pushDeviceToken {
            //Create a notification configuration if there's an available a device push notification token
            pushNotificationConfig = TxPushConfig(pushDeviceToken: pushToken)
        }
        self.ringBackTone = ringBackTone
        self.ringtone = ringtone
        self.reconnectClient = reconnectClient
        self.pushEnvironment = pushEnvironment
        self.debug = debug
        self.forceRelayCandidate = forceRelayCandidate
        self.customLogger = customLogger
        self.reconnectClient = reconnectClient
        self.enableQualityMetrics = enableQualityMetrics
        self.reconnectTimeout = reconnectTimeOut
        Logger.log.verboseLevel = logLevel
        Logger.log.customLogger = customLogger ?? TxDefaultLogger()
    }

    /// Constructor for the Telnyx SDK configuration using JWT token authentication.
    /// - Parameters:
    ///   - token: JWT token generated from https://developers.telnyx.com/docs/v2/webrtc/quickstart
    ///   - pushDeviceToken: (Optional) The device's push notification token, required for receiving inbound call notifications
    ///   - ringtone: (Optional) The audio file name to play for incoming calls (e.g., "my-ringtone.mp3")
    ///   - ringBackTone: (Optional) The audio file name to play while making outbound calls (e.g., "my-ringbacktone.mp3")
    ///   - logLevel: (Optional) The verbosity level for SDK logs (defaults to `.none`)
    ///   - customLogger: (Optional) Custom logger implementation for handling SDK logs. If not provided, the default logger will be used
    ///   - serverConfiguration: (Optional) Custom configuration for signaling server and TURN/STUN servers (defaults to Telnyx Production servers)
    ///   - reconnectTimeOut: (Optional) Maximum time in seconds the SDK will attempt to reconnect a call after network disruption. Default is 60 seconds.
    public init(token: String,
                pushDeviceToken: String? = nil,
                ringtone: String? = nil,
                ringBackTone: String? = nil,
                pushEnvironment: PushEnvironment? = nil,
                logLevel: LogLevel = .none,
                customLogger: TxLogger? = nil,
                reconnectClient: Bool = true,
                debug: Bool = false,
                forceRelayCandidate: Bool = false,
                enableQualityMetrics: Bool = false,
                reconnectTimeOut: Double = DEFAULT_TIMEOUT
    ) {
        self.token = token
        if let pushToken = pushDeviceToken {
            //Create a notification configuration if there's an available a device push notification token
            pushNotificationConfig = TxPushConfig(pushDeviceToken: pushToken)
        }
        self.ringBackTone = ringBackTone
        self.ringtone = ringtone
        self.pushEnvironment = pushEnvironment
        self.debug = debug
        self.forceRelayCandidate = forceRelayCandidate
        self.enableQualityMetrics = enableQualityMetrics
        self.customLogger = customLogger
        self.reconnectClient = reconnectClient
        self.reconnectTimeout = reconnectTimeOut
        Logger.log.verboseLevel = logLevel
        Logger.log.customLogger = customLogger ?? TxDefaultLogger()
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
