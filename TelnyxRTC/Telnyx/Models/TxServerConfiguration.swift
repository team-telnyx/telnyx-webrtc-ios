//
//  TxServerConfiguration.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 18/08/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import WebRTC
import Foundation

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
        
        self.pushMetaData = pushMetaData
        // Get rtc_id  to setup TxPushServerConfig
        let rtc_id = (pushMetaData?["voice_sdk_id"] as? String)

        
        Logger.log.i(message: "TxServerConfiguration:: signalingServer [\(String(describing: signalingServer))] webRTCIceServers [\(String(describing: webRTCIceServers))] environment [\(String(describing: environment))] ip - [\(String(describing: rtc_id))]")
        
        
        func createQuery(with rtc_id: String) -> String {
            let encodedId = rtc_id.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            return "?voice_sdk_id=\(encodedId)"
        }

        // Determine the base URL or host based on the environment or signalingServer
        if let signalingServer = signalingServer {
            if let rtc_id = rtc_id {
                // Use only the host of signalingServer if it already has queries
                let host = "wss://\(signalingServer.host ?? "")" 
                let query = createQuery(with: rtc_id)
                let pushRtcServer = "\(host)\(query)"
                self.signalingServer = URL(string: pushRtcServer) ?? signalingServer
            } else {
                self.signalingServer = signalingServer
            }
        } else {
            let baseURL = (environment == .production) ? InternalConfig.default.prodSignalingServer : InternalConfig.default.developmentSignalingServer
            if let rtc_id = rtc_id {
                let query = createQuery(with: rtc_id)
                let pushRtcServer = "\(baseURL.absoluteString)\(query)"
                self.signalingServer = URL(string: pushRtcServer) ?? baseURL
            } else {
                self.signalingServer = baseURL
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
