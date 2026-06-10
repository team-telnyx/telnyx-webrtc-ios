//
//  Socket.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 02/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation
import Starscream

class Socket {
    
    weak var delegate: SocketDelegate?
    var isConnected : Bool = false
    private var socket : WebSocket?
    private var reconnect : Bool = false
    internal var signalingServer:URL? = nil
    
    /// Timer for manual connection timeout (only used when not on auto region)
    private var connectionTimeoutTimer: Timer?
    
    /// Connection timeout interval in seconds
    private var connectionTimeout: TimeInterval = 5.0
    
    /// Call report ID captured from REGED message for stateless authentication
    /// Used to authenticate call quality reports posted to voice-sdk-proxy
    var callReportId: String?

    /// Voice SDK ID captured from REGED message
    /// Used as x-voice-sdk-id header when posting call reports
    var voiceSdkId: String?

    func connect(signalingServer: URL) {
        Logger.log.i(message: "Socket:: connect()")
        
        // Cancel any existing timeout timer
        cancelConnectionTimeout()
        
        var request = URLRequest(url: signalingServer)
        // Keep the underlying URLRequest timeout aligned with the watchdog interval
        // (configurable via setConnectionTimeout, minimum 5s). Previously this was
        // overwritten to 120s, which let a stalled handshake hang on the kernel's TCP
        // retransmit backoff with no recovery.
        request.timeoutInterval = connectionTimeout
        let pinner = FoundationSecurity(allowSelfSigned: true) // don't validate SSL certificates
        self.signalingServer = signalingServer

        self.socket = WebSocket(request: request, certPinner: pinner)
        self.socket?.delegate = self

        // Always start the connection-timeout watchdog. If the handshake stalls (e.g. a
        // lost SYN on cellular after a VoIP push), the timer fires and triggers a redial:
        // falling back to the auto region when on a specific region, otherwise redialing
        // the same signaling server.
        startConnectionTimeout()

        self.socket?.connect()
    }
    
    func disconnect(reconnect:Bool) {
        Logger.log.i(message: "Socket:: disconnect()")
        self.reconnect  = reconnect
        
        // Cancel timeout timer since we're explicitly disconnecting
        cancelConnectionTimeout()
        
        self.socket?.disconnect()
    }
    
    func sendMessage(message: String?) {
        if self.isConnected == false {
            Logger.log.e(message: "Socket:: not connected...")
            return
        }
        if let message = message,
           let socket = self.socket {
            socket.write(string: message)
            Logger.log.verto(message: "Socket:: sendMessage() message: \(message)", direction: .outbound)
        } else {
            Logger.log.e(message: "Socket:: sendMessage() Error sending message...")
        }
    }
    
}

// MARK:- WebSocketDelegate
extension Socket : WebSocketDelegate {
    // Fallback to .auto Region
    func shouldFallbackToAuto(signalingServer: URL?) -> Bool {
        guard let url = signalingServer,
              let regionPrefix = extractRegionPrefix(from: url),
              let region = Region(rawValue: regionPrefix) else {
            return false
        }
        return region != .auto
    }
    
    func extractRegionPrefix(from url: URL) -> String? {
        let host = url.host ?? ""
        let components = host.components(separatedBy: ".")
        if components.count >= 2 {
            return components[0] // e.g., "us-west"
        }
        return nil
    }

    
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(let headers):
            // Connection successful - cancel timeout timer
            cancelConnectionTimeout()
            isConnected = true
            self.delegate?.onSocketConnected()
            Logger.log.i(message: "Socket:: websocket is connected: \(headers)")
            break;
            
        case .disconnected(let reason, let code):
            //This are server side disconnections
            cancelConnectionTimeout()
            isConnected = false
            self.delegate?.onSocketDisconnected(reconnect: self.reconnect,region: nil)
            Logger.log.i(message: "Socket:: websocket is disconnected: \(reason) with code: \(code)")
            break;
            
        case .text(let message):
            Logger.log.verto(message: "\(message)", direction: .inbound)
            self.delegate?.onMessageReceived(message: message)
            break;

        case .cancelled:
            cancelConnectionTimeout()
            isConnected = false
            self.delegate?.onSocketDisconnected(reconnect: self.reconnect,region: nil)
            self.reconnect = false
            Logger.log.i(message: "Socket:: WebSocketDelegate .cancelled")
            break
            
        case .error(let error):
            cancelConnectionTimeout()
            isConnected = false
            guard let error = error else {
                Logger.log.e(message: "Socket:: WebSocketDelegate .error UNKNOWN")
                return
            }
            if(shouldFallbackToAuto(signalingServer: self.signalingServer)) {
                Logger.log.i(message: "Socket:: Triggering fallback to auto region due to error: \(error)")
                self.delegate?.onSocketDisconnected(reconnect: true,region: .auto)
            }
            self.delegate?.onSocketError(error: error)
            Logger.log.e(message: "Socket:: WebSocketDelegate .error \(error)")
            break;
            
        case .binary(let data):
            break
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .peerClosed:
            break
        @unknown default:
            break
        }
    }
    
    // MARK: - Connection Timeout Management
    
    /// Sets the connection timeout interval
    /// - Parameter timeout: Timeout interval in seconds (minimum 5 seconds)
    public func setConnectionTimeout(_ timeout: TimeInterval) {
        connectionTimeout = max(5.0, timeout)
    }
    
    /// Indicates whether the connection-timeout watchdog is currently armed.
    var isConnectionTimeoutActive: Bool {
        return connectionTimeoutTimer != nil
    }

    /// Starts the connection timeout watchdog timer.
    private func startConnectionTimeout() {
        connectionTimeoutTimer = Timer.scheduledTimer(withTimeInterval: connectionTimeout, repeats: false) { [weak self] _ in
            self?.handleConnectionTimeout()
        }
    }

    /// Cancels the connection timeout timer
    private func cancelConnectionTimeout() {
        connectionTimeoutTimer?.invalidate()
        connectionTimeoutTimer = nil
    }

    /// Handles connection timeout by redialing.
    ///
    /// When the socket is on a specific region that can fall back, the redial targets
    /// the auto region. Otherwise (e.g. the default `wss://rtc.telnyx.com` URL) it
    /// redials the same signaling server.
    func handleConnectionTimeout() {
        Logger.log.e(message: "Socket:: Connection timeout after \(connectionTimeout) seconds")

        // Mark as not connected and disconnect socket
        isConnected = false
        socket?.disconnect()

        // Fall back to the auto region only when we're on a fallback-able region;
        // otherwise redial the same server (region: nil).
        let redialRegion: Region? = shouldFallbackToAuto(signalingServer: signalingServer) ? .auto : nil
        Logger.log.i(message: "Socket:: Triggering redial due to timeout (region: \(String(describing: redialRegion)))")
        delegate?.onSocketDisconnected(reconnect: true, region: redialRegion)
    }
    
    
}
