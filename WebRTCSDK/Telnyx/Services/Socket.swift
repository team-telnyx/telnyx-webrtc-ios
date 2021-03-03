//
//  Socket.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 02/03/2021.
//

import Foundation
import Starscream

class Socket {
    
    var delegate: SocketDelegate?
    var isConnected : Bool = false

    private let config = InternalConfig.default
    private var socket : WebSocket?
    
    func connect() {
        print("Socket:: connect()")
        var request = URLRequest(url: config.signalingServerUrl)
        request.timeoutInterval = 5
        let pinner = FoundationSecurity(allowSelfSigned: true) // don't validate SSL certificates
        
        self.socket = WebSocket(request: request, certPinner: pinner)
        self.socket?.delegate = self
        self.socket?.connect()
    }
    
    func disconnect() {
        print("Socket:: disconnect()")
        self.socket?.disconnect()
    }
    
    func sendMessage(message: String?) {
        print("Socket:: sendMessage() sending message...")
        if let message = message,
           let socket = self.socket {
            socket.write(string: message)
            print("Socket:: sendMessage() message: \(message)")
        } else {
            print("Socket:: sendMessage() Error sending message...")
        }
    }
    
}

// MARK:- WebSocketDelegate
extension Socket : WebSocketDelegate {
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            isConnected = true
            self.delegate?.onSocketConnected()
            print("Socket:: websocket is connected: \(headers)")
            break;
            
        case .disconnected(let reason, let code):
            isConnected = false
            self.delegate?.onSocketDisconnected()
            print("Socket:: websocket is disconnected: \(reason) with code: \(code)")
            break;
            
        case .text(let message):
            print("Socket:: WebSocketDelegate .text \(message)")
            self.delegate?.onMessageReceived(message: message)
            break;
            
        case .cancelled:
            isConnected = false
            self.delegate?.onSocketError()
            print("Socket:: WebSocketDelegate .cancelled")
            break
            
        case .error(let error):
            isConnected = false
            self.delegate?.onSocketError()

            guard let error = error else {
                print("Socket:: WebSocketDelegate .error UNKNOWN")
                return
            }
            print("Socket:: WebSocketDelegate .error \(error)")
            break;
            
        case .binary(let data):
            print("Socket:: WebSocketDelegate .binary data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        }
    }
}
