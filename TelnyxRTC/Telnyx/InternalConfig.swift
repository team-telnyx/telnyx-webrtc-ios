//
//  Config.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 02/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation
import WebRTC

// MARK: - Production Servers
fileprivate let PROD_HOST = "wss://rtc.telnyx.com"
fileprivate let PROD_TURN_SERVER = "turn:turn.telnyx.com:3478?transport=tcp"
fileprivate let PROD_STUN_SERVER = "stun:stun.telnyx.com:3478"
fileprivate let PROD_TURN = RTCIceServer(urlStrings: [PROD_TURN_SERVER],
                                         username: "testuser",
                                         credential: "testpassword")
fileprivate let PROD_STUN = RTCIceServer(urlStrings: [PROD_STUN_SERVER])
fileprivate let prodIceServers = [PROD_TURN, PROD_STUN]

// MARK: - Development Servers
fileprivate let DEVELOPMENT_HOST = "wss://rtcdev.telnyx.com"
fileprivate let DEV_TURN_SERVER = "turn:turndev.telnyx.com:3478?transport=tcp"
fileprivate let DEV_STUN_SERVER = "stun:stundev.telnyx.com:3478"
fileprivate let DEV_TURN = RTCIceServer(urlStrings: [DEV_TURN_SERVER],
                                        username: "testuser",
                                        credential: "testpassword")
fileprivate let DEV_STUN = RTCIceServer(urlStrings: [DEV_STUN_SERVER])
fileprivate let devIceServers = [DEV_TURN, DEV_STUN]

// Set this to the machine's address which runs the signaling server
fileprivate let defaultSignalingServerUrl = URL(string: PROD_HOST)!

struct InternalConfig {
    let prodSignalingServer: URL
    let developmentSignalingServer: URL
    let prodWebRTCIceServers: [RTCIceServer]
    let devWebRTCIceServers: [RTCIceServer]
    
    static let prodTurnServer = PROD_TURN_SERVER
    static let prodStunServer = PROD_STUN_SERVER
    static let devTurnServer = DEV_TURN_SERVER
    static let devStunServer = DEV_STUN_SERVER

    static let `default` = InternalConfig(prodSignalingServer: URL(string: PROD_HOST)!,
                                          developmentSignalingServer: URL(string: DEVELOPMENT_HOST)!,
                                          prodWebRTCIceServers: prodIceServers,
                                          devWebRTCIceServers: devIceServers)
    
    // MARK: - Notification Names
    struct NotificationNames {
        static let acmResetStarted = "ACMResetStarted"
        static let acmResetCompleted = "ACMResetCompleted"
        static let audioRouteChanged = "AudioRouteChanged"
    }
}
