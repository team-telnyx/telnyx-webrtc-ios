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
// UDP preferred for lower latency, TCP as fallback for restrictive firewalls
fileprivate let PROD_TURN_SERVER_UDP = "turn:turn.telnyx.com:3478?transport=udp"
fileprivate let PROD_TURN_SERVER_TCP = "turn:turn.telnyx.com:3478?transport=tcp"
fileprivate let PROD_STUN_SERVER = "stun:stun.telnyx.com:3478"
// UDP TURN server (primary - lower latency)
fileprivate let PROD_TURN_UDP = RTCIceServer(urlStrings: [PROD_TURN_SERVER_UDP],
                                              username: "testuser",
                                              credential: "testpassword")
// TCP TURN server (fallback - for restrictive firewalls)
fileprivate let PROD_TURN_TCP = RTCIceServer(urlStrings: [PROD_TURN_SERVER_TCP],
                                              username: "testuser",
                                              credential: "testpassword")
fileprivate let PROD_STUN = RTCIceServer(urlStrings: [PROD_STUN_SERVER])
fileprivate let prodIceServers = [PROD_STUN, PROD_TURN_UDP, PROD_TURN_TCP]

// MARK: - Development Servers
fileprivate let DEVELOPMENT_HOST = "wss://rtcdev.telnyx.com"
// UDP preferred for lower latency, TCP as fallback for restrictive firewalls
fileprivate let DEV_TURN_SERVER_UDP = "turn:turndev.telnyx.com:3478?transport=udp"
fileprivate let DEV_TURN_SERVER_TCP = "turn:turndev.telnyx.com:3478?transport=tcp"
fileprivate let DEV_STUN_SERVER = "stun:stundev.telnyx.com:3478"
// UDP TURN server (primary - lower latency)
fileprivate let DEV_TURN_UDP = RTCIceServer(urlStrings: [DEV_TURN_SERVER_UDP],
                                             username: "testuser",
                                             credential: "testpassword")
// TCP TURN server (fallback - for restrictive firewalls)
fileprivate let DEV_TURN_TCP = RTCIceServer(urlStrings: [DEV_TURN_SERVER_TCP],
                                             username: "testuser",
                                             credential: "testpassword")
fileprivate let DEV_STUN = RTCIceServer(urlStrings: [DEV_STUN_SERVER])
fileprivate let devIceServers = [DEV_STUN, DEV_TURN_UDP, DEV_TURN_TCP]

// Set this to the machine's address which runs the signaling server
fileprivate let defaultSignalingServerUrl = URL(string: PROD_HOST)!

struct InternalConfig {
    let prodSignalingServer: URL
    let developmentSignalingServer: URL
    let prodWebRTCIceServers: [RTCIceServer]
    let devWebRTCIceServers: [RTCIceServer]
    
    // Primary TURN servers (UDP - lower latency)
    static let prodTurnServer = PROD_TURN_SERVER_UDP
    static let prodTurnServerTcp = PROD_TURN_SERVER_TCP
    static let prodStunServer = PROD_STUN_SERVER
    static let devTurnServer = DEV_TURN_SERVER_UDP
    static let devTurnServerTcp = DEV_TURN_SERVER_TCP
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
