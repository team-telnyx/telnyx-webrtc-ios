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
    public internal(set) var canary: Bool?
    public internal(set) var webRTCIceServers: [RTCIceServer]

    /// Constructor for the Server configuration parameters.
    /// - Parameters:
    ///   - signalingServer: To define the signaling server URL `wss://address:port`
    ///   - webRTCIceServers: To define custom ICE servers
    ///   - pushMetaData: Contains push info when a PN is received
    public init(signalingServer: URL? = nil, webRTCIceServers: [RTCIceServer]? = nil, environment: WebRTCEnvironment = .production,pushMetaData:[String: Any]? = nil, canary: Bool? = nil, region:Region = Region.auto) {
        
        self.pushMetaData = pushMetaData
        self.canary = canary
        // Get rtc_id  to setup TxPushServerConfig
        let rtc_id = (pushMetaData?["voice_sdk_id"] as? String)

        Logger.log.i(message: "TxServerConfiguration:: signalingServer [\(String(describing: signalingServer))] webRTCIceServers [\(String(describing: webRTCIceServers))] environment [\(String(describing: environment))] ip - [\(String(describing: rtc_id))] canary [\(String(describing: canary))] region [\(region)]")
        
        let regionPrefix: String = {
            if region != .auto {
                   return "\(region.rawValue)."
               }
               return ""
           }()

        func configuredSignalingServer(from baseURL: URL) -> URL {
            guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
                return baseURL
            }

            if let host = components.host, !regionPrefix.isEmpty, !host.hasPrefix(regionPrefix) {
                components.host = "\(regionPrefix)\(host)"
            }

            var queryItems = components.queryItems ?? []
            queryItems.removeAll { $0.name == "voice_sdk_id" || $0.name == "canary" }

            if let rtc_id = rtc_id {
                queryItems.append(URLQueryItem(name: "voice_sdk_id", value: rtc_id))
            }

            if let canary = canary {
                queryItems.append(URLQueryItem(name: "canary", value: canary ? "true" : "false"))
            }

            components.queryItems = queryItems.isEmpty ? nil : queryItems
            return components.url ?? baseURL
        }

        // Determine the base URL or host based on the environment or signalingServer
        if let signalingServer = signalingServer {
            self.signalingServer = configuredSignalingServer(from: signalingServer)
        } else {
            // Always use production server unless explicitly set to development
            let baseURL = (environment == .development) ? InternalConfig.default.developmentSignalingServer : InternalConfig.default.prodSignalingServer
            self.signalingServer = configuredSignalingServer(from: baseURL)
            self.environment = environment
        }

        if let webRTCIceServers = webRTCIceServers {
            self.webRTCIceServers = webRTCIceServers
        } else {
            // Always use production servers unless explicitly set to development
            self.webRTCIceServers = (environment == .development)
                ? InternalConfig.default.devWebRTCIceServers
                : InternalConfig.default.prodWebRTCIceServers
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
