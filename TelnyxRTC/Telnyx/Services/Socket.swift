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

    func connect(signalingServer: URL) {
        Logger.log.i(message: "Socket:: connect()")
        
        // Cancel any existing timeout timer
        cancelConnectionTimeout()
        
        var request = URLRequest(url: signalingServer)
        request.timeoutInterval = connectionTimeout
        let pinner = FoundationSecurity(allowSelfSigned: true) // don't validate SSL certificates
        self.signalingServer = signalingServer
        
        self.socket = WebSocket(request: request, certPinner: pinner)
        self.socket?.delegate = self
        self.socket?.request.timeoutInterval = TimeInterval(120)
        
        // Only start timeout timer if we can fallback to auto (i.e., not already on auto)
        if shouldFallbackToAuto(signalingServer: signalingServer) {
            startConnectionTimeout()
        }
        
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
    
    /// Starts the connection timeout timer (only when not on auto region)
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
    
    /// Handles connection timeout by triggering fallback mechanism
    private func handleConnectionTimeout() {
        Logger.log.e(message: "Socket:: Connection timeout after \(connectionTimeout) seconds")
        
        // Mark as not connected and disconnect socket
        isConnected = false
        socket?.disconnect()
        
        // Trigger fallback to auto region (we know we can fallback since timer only starts when shouldFallbackToAuto is true)
        Logger.log.i(message: "Socket:: Triggering fallback to auto region due to timeout")
        delegate?.onSocketDisconnected(reconnect: true, region: .auto)
    }
    
    
}
