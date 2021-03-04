//
//  Config.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 02/03/2021.
//

//
//  Config.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 08/01/2021.
//
import Foundation
import WebRTC
//Servers
fileprivate let PROD_HOST = "wss://rtc.telnyx.com:14938"
fileprivate let DEVELOPMENT_HOST = "wss://rtcdev.telnyx.com:14938"

fileprivate let DEFAULT_TURN = RTCIceServer(urlStrings: ["turn:turn.telnyx.com:3478?transport=tcp"],
                                            username: "testuser",
                                            credential: "testpassword")
fileprivate let DEFAULT_STUN = RTCIceServer(urlStrings: ["stun:stun.telnyx.com:3843"])

// Set this to the machine's address which runs the signaling server
fileprivate let defaultSignalingServerUrl = URL(string: PROD_HOST)!
fileprivate let defaultIceServers = [DEFAULT_TURN, DEFAULT_STUN]

struct InternalConfig {
    let signalingServerUrl: URL
    let webRTCIceServers: [RTCIceServer]
    
    static let `default` = InternalConfig(signalingServerUrl: defaultSignalingServerUrl,
                                  webRTCIceServers: defaultIceServers)
}
