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
private let prodHost = "wss://rtc.telnyx.com"
// UDP preferred for lower latency, TCP as fallback for restrictive firewalls
private let prodTurnServerUdp = "turn:turn.telnyx.com:3478?transport=udp"
private let prodTurnTcpUrl = "turn:turn.telnyx.com:3478?transport=tcp"
private let prodStunUrl = "stun:stun.telnyx.com:3478"
// UDP TURN server (primary - lower latency)
private let prodTurnUdp = RTCIceServer(urlStrings: [prodTurnServerUdp],
                                        username: "testuser",
                                        credential: "testpassword")
// TCP TURN server (fallback - for restrictive firewalls)
private let prodTurnTcp = RTCIceServer(urlStrings: [prodTurnTcpUrl],
                                        username: "testuser",
                                        credential: "testpassword")
private let prodStun = RTCIceServer(urlStrings: [prodStunUrl])
// Google STUN server for additional STUN redundancy (aligned with JS WebRTC SDK)
private let googleStun = RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
private let prodIceServers = [prodStun, googleStun, prodTurnUdp, prodTurnTcp]

// MARK: - Development Servers
private let developmentHost = "wss://rtcdev.telnyx.com"
// UDP preferred for lower latency, TCP as fallback for restrictive firewalls
private let devTurnServerUdp = "turn:turndev.telnyx.com:3478?transport=udp"
private let devTurnTcpUrl = "turn:turndev.telnyx.com:3478?transport=tcp"
private let devStunUrl = "stun:stundev.telnyx.com:3478"
// UDP TURN server (primary - lower latency)
private let devTurnUdp = RTCIceServer(urlStrings: [devTurnServerUdp],
                                       username: "testuser",
                                       credential: "testpassword")
// TCP TURN server (fallback - for restrictive firewalls)
private let devTurnTcp = RTCIceServer(urlStrings: [devTurnTcpUrl],
                                       username: "testuser",
                                       credential: "testpassword")
private let devStun = RTCIceServer(urlStrings: [devStunUrl])
private let devIceServers = [devStun, googleStun, devTurnUdp, devTurnTcp]

// Set this to the machine's address which runs the signaling server
private let defaultSignalingServerUrl = URL(string: prodHost)!

struct InternalConfig {
    let prodSignalingServer: URL
    let developmentSignalingServer: URL
    let prodWebRTCIceServers: [RTCIceServer]
    let devWebRTCIceServers: [RTCIceServer]

    // Primary TURN servers (UDP - lower latency)
    static let prodTurnServer = prodTurnServerUdp
    static let prodTurnServerTcp = prodTurnTcpUrl
    static let prodStunServer = prodStunUrl
    static let devTurnServer = devTurnServerUdp
    static let devTurnServerTcp = devTurnTcpUrl
    static let devStunServer = devStunUrl

    static let `default` = InternalConfig(prodSignalingServer: URL(string: prodHost)!,
                                          developmentSignalingServer: URL(string: developmentHost)!,
                                          prodWebRTCIceServers: prodIceServers,
                                          devWebRTCIceServers: devIceServers)

    // MARK: - Notification Names
    struct NotificationNames {
        static let acmResetStarted = "ACMResetStarted"
        static let acmResetCompleted = "ACMResetCompleted"
        static let audioRouteChanged = "AudioRouteChanged"
    }
}
