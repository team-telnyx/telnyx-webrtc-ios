//
//  Config.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 02/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation
import WebRTC
//Servers
fileprivate let PROD_HOST = "wss://rtc.telnyx.com"
fileprivate let DEVELOPMENT_HOST = "wss://rtcdev.telnyx.com"

fileprivate let DEFAULT_TURN = RTCIceServer(urlStrings: ["turn:turn.telnyx.com:3478?transport=tcp"],
                                            username: "testuser",
                                            credential: "testpassword")
fileprivate let DEFAULT_STUN = RTCIceServer(urlStrings: ["stun:stun.telnyx.com:3843"])

// Set this to the machine's address which runs the signaling server
fileprivate let defaultSignalingServerUrl = URL(string: PROD_HOST)!
fileprivate let defaultIceServers = [DEFAULT_TURN, DEFAULT_STUN]

struct InternalConfig {
    let bugsnagKey = "046a0602ac5080aee24906a0191f867d"
    let prodSignalingServer: URL
    let developmentSignalingServer: URL
    let webRTCIceServers: [RTCIceServer]
    
    static let `default` = InternalConfig(prodSignalingServer: URL(string: PROD_HOST)!,
                                          developmentSignalingServer: URL(string: DEVELOPMENT_HOST)!,
                                          webRTCIceServers: defaultIceServers)
}
