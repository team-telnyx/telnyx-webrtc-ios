//
//  TxClient.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 01/03/2021.
//

import Foundation
import AVFoundation


/// The `TelnyxRTC` client connects your application to the Telnyx backend,
/// enabling you to make outgoing calls and handle incoming calls.
public class TxClient {

    /// Keeps track of all the created calls by theirs UUIDs
    public var calls: [UUID: Call] = [UUID: Call]()
    /// Subscribe to TxClient delegate to receive Telnyx RTC events
    public var delegate: TxClientDelegate?
    private var socket : Socket?

    private var sessionId : String?
    private var txConfig: TxConfig?

    private var ringTonePlayer: AVAudioPlayer?
    private var ringbackPlayer: AVAudioPlayer?

    public init() {}

    /// Connects to the iOS client to the Telnyx signaling server using the desired login credentials.
    /// - Parameter txConfig: txConfig. The desired login credentials. See TxConfig docummentation for more information.
    /// - Throws: TxConfig parameters errors
    public func connect(txConfig: TxConfig) throws {
        print("TxClient:: connect()")
        //Check connetion parameters
        try txConfig.validateParams()

        self.txConfig = txConfig
        self.socket = Socket()
        self.socket?.delegate = self
        self.socket?.connect()
    }

    /// Disconnects the TxClient from the Telnyx signaling server.
    public func disconnect() {
        print("TxClient:: disconnect()")
        socket?.disconnect()
        socket = nil
        delegate?.onSocketDisconnected()
    }

    /// Obtaian the current session ID after loggin in to Telnyx server.
    /// - Returns: The current sessionId. If this value is empty, that means that the client is not connected to Telnyx server.
    public func getSessionId() -> String {
        return sessionId ?? ""
    }

    /// Check if TxClient is connected to Telnyx servers.
    /// - Returns: `true` if TxClient socket is connected, `false` otherwise.
    public func isConnected() -> Bool {
        guard let isConnected = socket?.isConnected else { return false }
        return isConnected
    }
}

// MARK: - Call handling
extension TxClient {

    /// Get the current Call state.
    /// - Returns: returns the current call state `CallState`. If there's no call, the returned value is `NEW`
    public func getCallState() -> CallState {
        return self.calls.first?.value.callState ?? .NEW
    }

    /// Creates a Call and starts the call sequence, negotiate the ICE Candidates and sends the invite.
    /// - Parameters:
    ///   - callerName: The caller name. This will be displayed as the caller name in the remote's client.
    ///   - callerNumber: The caller Number. The phone number of the current user.
    ///   - destinationNumber: The destination `SIP user address` (sip:YourSipUser@sip.telnyx.com) or `phone number`.
    ///   - callId: The current call UUID.
    /// - Throws:
    ///   - sessionId is required if user is not logged in
    ///   - socket connection error if socket is not connected
    ///   - destination number is required to start a call.
    public func newCall(callerName: String,
                 callerNumber: String,
                 destinationNumber: String,
                 callId: UUID) throws -> Call {
        //User needs to be logged in to get a sessionId
        guard let sessionId = self.sessionId else {
            throw TxError.callFailed(reason: .sessionIdIsRequired)
        }
        //A socket connection is required
        guard let socket = self.socket,
              socket.isConnected else {
            throw TxError.socketConnectionFailed(reason: .socketNotConnected)
        }

        //A destination number or sip address is required to start a call
        if destinationNumber.isEmpty {
            throw TxError.callFailed(reason: .destinationNumberIsRequired)
        }

        let call = Call(callId: callId, sessionId: sessionId, socket: socket, delegate: self)
        call.newCall(callerName: callerName, callerNumber: callerNumber, destinationNumber: destinationNumber)

        self.calls[callId] = call
        return call
    }


    /// Call this function to hangup an ongoing call
    public func hangup() {
        self.stopRingtone()
        self.stopRingbackTone()
        self.calls.first?.value.hangup()
    }


    /// Call this function to answer an incoming call
    public func answer() {
        self.stopRingtone()
        self.calls.first?.value.answerCall()
    }

    fileprivate func createIncomingCall(callerName: String, callerNumber: String, callId: UUID, remoteSdp: String) {

        guard let sessionId = self.sessionId,
              let socket = self.socket else {
            return
        }

        let call = Call(callId: callId, remoteSdp: remoteSdp, sessionId: sessionId, socket: socket, delegate: self)
        call.callInfo?.callerName = callerName
        call.callInfo?.callerNumber = callerNumber
        call.callOptions = TxCallOptions(audio: true)

        self.calls[callId] = call
        guard let callInfo = call.callInfo else { return }

        self.delegate?.onIncomingCall(callInfo: callInfo)
    }
}

// MARK: - Audio
extension TxClient {

    /// Mutes the audio of the active call.
    public func muteAudio() {
        self.calls.first?.value.muteAudio()
    }

    /// Unmutes the audio of the active call.
    public func unmuteAudio() {
        self.calls.first?.value.muteAudio()
    }
}
// MARK: - Hold Unhold
extension TxClient {

    /// Hold the Call
    public func hold() {
        self.calls.first?.value.hold()
    }

    /// Unhold the Call
    public func unhold() {
        self.calls.first?.value.unhold()
    }
}

// MARK: - Ringtone and Ringback tone handling
extension TxClient {

    private func playRingtone() {
        print("TxClient:: playRingtone()")
        guard let ringtone = self.txConfig?.ringtone else { return }
        if self.ringTonePlayer == nil {
            self.ringTonePlayer = self.buildAudioPlayer(fileName: ringtone)
        }
        guard let ringtonePlayer = self.ringTonePlayer else { return  }

        ringtonePlayer.numberOfLoops = -1 // infinite
        ringtonePlayer.play()
    }

    private func stopRingtone() {
        print("TxClient:: stopRingtone()")
        self.ringTonePlayer?.stop()
    }

    private func playRingbackTone() {
        print("TxClient:: playRingbackTone()")
        guard let ringback = self.txConfig?.ringBackTone else { return }
        if self.ringbackPlayer == nil {
            self.ringbackPlayer = self.buildAudioPlayer(fileName: ringback)
        }
        guard let ringbackPlayer = self.ringbackPlayer else { return  }

        ringbackPlayer.numberOfLoops = -1 // infinite
        ringbackPlayer.play()
    }

    private func stopRingbackTone() {
        print("TxClient:: stopRingbackTone()")
        self.ringbackPlayer?.stop()
    }

    private func buildAudioPlayer(fileName: String) -> AVAudioPlayer? {
        print("TxClient:: buildAudioPlayer fileName: \(fileName)")
        guard let path = Bundle.main.path(forResource: fileName, ofType: nil ) else {
            print("TxClient:: buildAudioPlayer() file not found: \(fileName).")
            return nil
        }
        let url = URL(fileURLWithPath: path)
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient)
            try AVAudioSession.sharedInstance().setActive(true)
            return audioPlayer
        } catch{
            print("TxClient:: buildAudioPlayer() error: \(error)")
        }
        return nil
    }
}
// MARK: - CallProtocol
extension TxClient: CallProtocol {

    func callStateUpdated(call: Call) {
        //Forward call state
        self.delegate?.onCallStateUpdated(callState: call.callState)

        //Remove call if it has ended
        if call.callState == .DONE ,
           let callId = call.callInfo?.callId {
            self.calls.removeValue(forKey: callId)
        }
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
        
        //Login into the signaling server after the connection is produced.
        if let token = self.txConfig?.token  {
            print("TxClient:: SocketDelegate onSocketConnected() login with Token")
            let vertoLogin = LoginMessage(token: token)
            self.socket?.sendMessage(message: vertoLogin.encode())
        } else {
            print("TxClient:: SocketDelegate onSocketConnected() login with SIP User and Password")
            guard let sipUser = self.txConfig?.sipUser else { return }
            guard let password = self.txConfig?.password else { return }
            let vertoLogin = LoginMessage(user: sipUser, password: password)
            self.socket?.sendMessage(message: vertoLogin.encode())
        }
    }
    
    func onSocketDisconnected() {
        print("TxClient:: SocketDelegate onSocketDisconnected()")
        self.delegate?.onSocketDisconnected()
    }

    func onSocketError(error: Error) {
        print("TxClient:: SocketDelegate onSocketError()")
        self.delegate?.onClientError(error: error)
    }

    /**
     Each time we receive a message throught  the WSS this method will be called.
     Here we are checking the mesaging
     */
    func onMessageReceived(message: String) {
        print("TxClient:: SocketDelegate onMessageReceived() message: \(message)")
        guard let vertoMessage = Message().decode(message: message) else { return }

        //Check if server is sending an error code
        if let error = vertoMessage.serverError {
            let message : String = error["message"] as? String ?? "Unknown"
            let code : String = String(error["code"] as? Int ?? 0)
            let err = TxError.serverError(reason: .signalingServerError(message: message, code: code))
            self.delegate?.onClientError(error: err)
        }

        //Check if we are getting the new sessionId in response to the "login" message.
        if let result = vertoMessage.result {
            //process result
            guard let sessionId = result["sessid"] as? String else { return }
            //keep the sessionId
            self.sessionId = sessionId
            self.delegate?.onSessionUpdated(sessionId: sessionId)
        } else {

            //Forward message to call based on it's uuid
            if let params = vertoMessage.params,
               let callUUIDString = params["callID"] as? String,
               let callUUID = UUID(uuidString: callUUIDString),
               let call = calls[callUUID] {
                call.handleVertoMessage(message: vertoMessage)
            }

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
                    self.stopRingtone()
                    self.stopRingbackTone()
                }
                break

            case .ANSWER:
                //When the remote peer answers the call
                //Set the remote SDP into the current RTCPConnection and the call should start!
                self.stopRingtone()
                self.stopRingbackTone()
                break;

            case .INVITE:
                //invite received
                if let params = vertoMessage.params {
                    guard let sdp = params["sdp"] as? String,
                          let callId = params["callID"] as? String,
                          let uuid = UUID(uuidString: callId) else {
                        return
                    }

                    let callerName = params["caller_id_name"] as? String ?? ""
                    let callerNumber = params["caller_id_number"] as? String ?? ""

                    self.createIncomingCall(callerName: callerName, callerNumber: callerNumber, callId: uuid, remoteSdp: sdp)
                    self.playRingtone()
                }
                break;

            case .RINGING:
                self.playRingbackTone()
                break
            default:
                print("TxClient:: SocketDelegate Default method")
                break
            }
        }
    }
}
