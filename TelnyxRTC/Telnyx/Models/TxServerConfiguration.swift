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
    public internal(set) var pushMetaData: [String:Any]?
    public internal(set) var webRTCIceServers: [RTCIceServer]

    /// Constructor for the Server configuration parameters.
    /// - Parameters:
    ///   - signalingServer: To define the signaling server URL `wss://address:port`
    ///   - webRTCIceServers: To define custom ICE servers
    ///   - pushMetaData: Contains push info when a PN is received
    public init(signalingServer: URL? = nil, webRTCIceServers: [RTCIceServer]? = nil, environment: WebRTCEnvironment = .production,pushMetaData:[String: Any]? = nil) {
        
        // Get rtc_ip and rct_port to setup TxPushServerConfig
        let rtc_id = (pushMetaData?["voice_sdk_id"] as? String)

        self.pushMetaData = pushMetaData
    
        Logger.log.i(message: "TxServerConfiguration:: signalingServer [\(String(describing: signalingServer))] webRTCIceServers [\(String(describing: webRTCIceServers))] environment [\(String(describing: environment))] ip - [\(String(describing: rtc_id))]")
        
        
        if let signalingServer = signalingServer {
            self.signalingServer = signalingServer
        } else {
            if environment == .production {
                // Set signalingServer for push notifications
                //pass voice_sdk_id fot proxy to assign the right instance to call
                if let pushId = rtc_id {
                    let encodedId = pushId.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
                    let query = "?voice_sdk_id=\(encodedId)"
                    let pushRtcServer = "\(InternalConfig.default.prodSignalingServer)\(query)"
                    self.signalingServer = URL(string: pushRtcServer ) ??  InternalConfig.default.prodSignalingServer
                    
                }else {
                    self.signalingServer = InternalConfig.default.prodSignalingServer
                }
            } else {
                
                // Set signalingServer for push notifications
                //pass voice_sdk_id for proxy to assign the right instance to call
                if let pushId = rtc_id {
                    let query = "?voice_sdk_id=\(pushId)"
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

import Foundation

extension String {

    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }

}
