//
//  TxServerConfiguration.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 18/08/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import WebRTC

public enum WebRTCEnvironment {
    case development
    case production
}
/// This class contains all the properties related to: Signaling server URL and  STUN / TURN servers
public struct TxServerConfiguration {

    public internal(set) var environment: WebRTCEnvironment = .production
    public internal(set) var signalingServer: URL
    public internal(set) var webRTCIceServers: [RTCIceServer]

    /// Constructor for the Server configuration parameters.
    /// - Parameters:
    ///   - signalingServer: To define the signaling server URL `wss://address:port`
    ///   - webRTCIceServers: To define custom ICE servers
    ///   - pushMetaData: Contains push info when a PN is received
    public init(signalingServer: URL? = nil, webRTCIceServers: [RTCIceServer]? = nil, environment: WebRTCEnvironment = .production,pushMetaData:[String: Any]? = nil) {
        
        
        let rtcId = (pushMetaData?["rtc_id"] as? String)
        
        // Get rtc_ip and rct_port to setup TxPushServerConfig
        let rtc_ip = (pushMetaData?["rtc_ip"] as? String)
        let rtc_port = (pushMetaData?["rtc_port"] as? Int) ?? 0
        
        
        
        Logger.log.i(message: "TxServerConfiguration:: signalingServer [\(String(describing: signalingServer))] webRTCIceServers [\(String(describing: webRTCIceServers))] environment [\(String(describing: environment))]")
        if let signalingServer = signalingServer {
            self.signalingServer = signalingServer
        } else {
            if environment == .production {
                // Set signalingServer for push notifications
                if let pushId = rtc_ip {
                    let query = "?rtc_ip=\(pushId)&rtc_port=\(rtc_port)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    let pushRtcServer = "\(InternalConfig.default.prodSignalingServer)\(query)"
                    self.signalingServer = URL(string: pushRtcServer ) ??  InternalConfig.default.prodSignalingServer
                    
                }else {
                    self.signalingServer = InternalConfig.default.prodSignalingServer
                }
                
            } else {
                
                // Set signalingServer for push notifications
                if let pushId = rtc_ip {
                    let query = "?rtc_ip=\(pushId)&rtc_port=\(rtc_port)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    let pushRtcServer = "\(InternalConfig.default.developmentSignalingServer)\(query)"
                    self.signalingServer = URL(string: pushRtcServer ) ?? InternalConfig.default.developmentSignalingServer
                    
                }else {
                    self.signalingServer = InternalConfig.default.developmentSignalingServer
                }
                
            }
            self.environment = environment
        }

        if let webRTCIceServers = webRTCIceServers {
            self.webRTCIceServers = webRTCIceServers
        } else {
            self.webRTCIceServers = InternalConfig.default.webRTCIceServers
        }
    }
}
