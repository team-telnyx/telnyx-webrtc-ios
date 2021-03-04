//
//  TxClient.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 01/03/2021.
//

import Foundation

public class TxClient {
    private let CURRENT_VERSION = "1.0.0"
    
    public var delegate: TxClientDelegate?
    private var socket : Socket?
    
    private var sessionId : String?
    private var txConfig: TxConfig?

    public init() {}
    
    public func getVersion() -> String {
        return CURRENT_VERSION
    }
    
    public func connect(txConfig: TxConfig) {
        print("TxClient:: connect()")
        self.txConfig = txConfig
        self.socket = Socket()
        self.socket?.delegate = self
        self.socket?.connect()
    }
    
    public func disconnect() {
        print("TxClient:: disconnect()")
        socket?.disconnect()
        socket = nil
        delegate?.onSocketDisconnected()
    }
    
    public func getSessionId() -> String {
        return sessionId ?? ""
    }
    
    public func isConnected() -> Bool {
        guard let isConnected = socket?.isConnected else { return false }
        return isConnected
    }
}

// MARK: - SocketDelegate
/**
 Listen for wss socket events
 */
extension TxClient : SocketDelegate {
    
    func onSocketConnected() {
        print("TxClient:: SocketDelegate onSocketConnected()")
        self.delegate?.onSocketConnected()
        
        guard let sipUser = self.txConfig?.sipUser else { return }
        guard let password = self.txConfig?.password else { return }
        //Login into the signaling server after the connection is produced.
        //TODO: Implement login by Token
        let vertoLogin = LoginMessage(user: sipUser, password: password)
        self.socket?.sendMessage(message: vertoLogin.encode())
    }
    
    func onSocketDisconnected() {
        print("TxClient:: SocketDelegate onSocketDisconnected()")
        self.delegate?.onSocketDisconnected()
    }
    
    func onSocketError() {
        print("TxClient:: SocketDelegate onSocketError()")
    }
    
    /**
     Each time we receive a message throught  the WSS this method will be called.
     Here we are checking the mesaging
     */
    func onMessageReceived(message: String) {
        print("TxClient:: SocketDelegate onMessageReceived() message: \(message)")
        guard let vertoMessage = Message().decode(message: message) else { return }
        
        //Check if we are getting the new sessionId in response to the "login" message.
        if let result = vertoMessage.result {
            //process result
            guard let sessionId = result["sessid"] as? String else { return }
            //keep the sessionId
            self.sessionId = sessionId
            self.delegate?.onSessionUpdated(sessionId: sessionId)
        } else {
            //Parse incoming Verto message
            switch vertoMessage.method {
            case .CLIENT_READY:
                self.delegate?.onClientReady()
                break
            default:
                print("TxClient:: SocketDelegate Default method")
                break
            }
        }
    }
    
    
}
