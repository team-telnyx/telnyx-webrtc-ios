//
//  TxClient.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 01/03/2021.
//

import Foundation

public class TxClient {
    private let CURRENT_VERSION = "1.0.0"
    
    private var delegate: TxClientDelegate?
    private var socket : Socket?

    public init() {}
    
    public func getVersion() -> String {
        return CURRENT_VERSION
    }
    
    public func connect() {
        print("TxClient:: connect()")
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
}

// MARK: - SocketDelegate
/**
 Listen for wss socket events
 */
extension TxClient : SocketDelegate {
    
    func onSocketConnected() {
        print("TxClient:: SocketDelegate onSocketConnected()")
        self.delegate?.onSocketConnected()
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
    }
    
    
}
