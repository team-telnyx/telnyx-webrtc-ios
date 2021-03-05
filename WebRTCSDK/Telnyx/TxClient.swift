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
    private var call: Call?

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

// MARK: - Call handling
extension TxClient {

    public func getCallState() -> CallState {
        return self.call?.callState ?? .NEW
    }
    /**
        Creates a Call and starts the call sequence, negotiate the ICE Candidates and sends the invite.
        destinationNumber: Phone number or SIP address to call.
     */
    public func newCall(callerName: String,
                 callerNumber: String,
                 destinationNumber: String,
                 callId: UUID) {
        guard let sessionId = self.sessionId else {
            return
        }
        
        guard let socket = self.socket else {
            return
        }

        self.call = Call(callId: callId, sessionId: sessionId, socket: socket, delegate: self)
        self.call?.newCall(callerName: callerName, callerNumber: callerNumber, destinationNumber: destinationNumber)
    }

    public func hangup() {
        self.call?.hangup()
    }

    public func answer() {
        self.call?.answerCall()
    }

    fileprivate func createIncomingCall(callerName: String, callerNumber: String, callId: UUID, remoteSdp: String) {

        guard let sessionId = self.sessionId,
              let socket = self.socket else {
            return
        }

        self.call = Call(callId: callId, remoteSdp: remoteSdp, sessionId: sessionId, socket: socket, delegate: self)

        self.call?.callInfo?.callerName = callerName
        self.call?.callInfo?.callerNumber = callerNumber
        self.call?.callOptions = TxCallOptions(audio: true)

        guard let callInfo = self.call?.callInfo else { return }

        self.delegate?.onIncomingCall(callInfo: callInfo)
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
            
            case .BYE:
                //invite received
                if let params = vertoMessage.params {
                    guard let callId = params["callID"] as? String,
                          let uuid = UUID(uuidString: callId) else {
                        return
                    }
                    self.delegate?.onRemoteCallEnded(callId: uuid)
                    self.call?.endCall()
                }
                break
            case .ANSWER:
                //When the remote peer answers the call
                //Set the remote SDP into the current RTCPConnection and the call should start!
                if let params = vertoMessage.params {
                    guard let remoteSdp = params["sdp"] as? String else {
                        return
                    }
                    //retrieve the remote SDP from the ANSWER verto message and set it to the current RTCPconnection
                    self.call?.answered(sdp: remoteSdp)
                }
                break;

            case .INVITE:
                //invite received
                if let params = vertoMessage.params {
                    guard let sdp = params["sdp"] as? String else {
                        return
                    }
                    guard let callId = params["callID"] as? String,
                          let uuid = UUID(uuidString: callId) else {
                        return
                    }

                    guard let callerName = params["caller_id_name"] as? String else {
                        return
                    }

                    guard let callerNumber = params["caller_id_number"] as? String else {
                        return
                    }

                    self.createIncomingCall(callerName: callerName, callerNumber: callerNumber, callId: uuid, remoteSdp: sdp)
                }
                break;

            default:
                print("TxClient:: SocketDelegate Default method")
                break
            }
        }
    }
}

// MARK: - CallProtocol
extension TxClient: CallProtocol {
    func callStateUpdated(callState: CallState) {
        self.delegate?.onCallStateUpdated(callState: callState)
    }
}
