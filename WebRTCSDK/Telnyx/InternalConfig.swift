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

//Servers
fileprivate let PROD_HOST = "wss://rtc.telnyx.com:14938"
fileprivate let DEVELOPMENT_HOST = "wss://rtcdev.telnyx.com:14938"

// Set this to the machine's address which runs the signaling server
fileprivate let defaultSignalingServerUrl = URL(string: PROD_HOST)!

struct InternalConfig {
    let signalingServerUrl: URL
    
    static let `default` = InternalConfig(signalingServerUrl: defaultSignalingServerUrl)
}
