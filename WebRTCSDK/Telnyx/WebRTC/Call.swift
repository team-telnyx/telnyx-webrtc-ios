//
//  Call.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 03/03/2021.
//

import Foundation
import WebRTC

public enum CallState {
    case NEW
    case CONNECTING
    case RINGING
    case ACTIVE
    case HELD
    case DONE
}

enum CallDirection : String {
    case INBOUND = "inbound"
    case OUTBOUND = "outbound"
}


protocol CallProtocol {
    func callStateUpdated(callState: CallState)
}

class Call {
    
    var negotiationEnded: Bool = false

    var direction: CallDirection = .OUTBOUND
    var config: InternalConfig = InternalConfig.default
    var peer: Peer?
    var socket: Socket?
    var delegate: CallProtocol?

    var sessionId: String?
    var remoteSdp: String?
    var callInfo: TxCallInfo?
    var callOptions: TxCallOptions?
    var callState: CallState = .NEW
    
    init(callId: UUID,
         remoteSdp: String,
         sessionId: String,
         socket: Socket,
         delegate: CallProtocol) {
        self.direction = CallDirection.INBOUND
        //Session obtained after login with the signaling socket
        self.sessionId = sessionId
        //this is the signaling server socket
        self.socket = socket
        
        self.remoteSdp = remoteSdp
        self.callInfo = TxCallInfo(callId: callId)
        self.delegate = delegate
        updateCallState(callState: .NEW)
    }
    
    init(callId: UUID, sessionId: String, socket: Socket, delegate: CallProtocol) {
        //Session obtained after login with the signaling socket
        self.sessionId = sessionId
        //this is the signaling server socket
        self.socket = socket
        self.callInfo = TxCallInfo(callId: callId)
        self.delegate = delegate
        self.updateCallState(callState: .RINGING)
    }
    
    func newCall(callerName: String,
                 callerNumber: String,
                 destinationNumber: String) {
        if (destinationNumber.isEmpty) {
            print("Please enter a destination number.")
            return
        }
        invite(callerName: callerName, callerNumber: callerNumber, destinationNumber: destinationNumber)
    }
    
    /**
        Creates an offer to start the calling process
     */
    private func invite(callerName: String, callerNumber: String, destinationNumber: String) {
        self.direction = .OUTBOUND
        
        self.callInfo?.callerName = callerName
        self.callInfo?.callerNumber = callerNumber
        self.callOptions = TxCallOptions(destinationNumber: destinationNumber)
        
        self.peer = Peer(iceServers: self.config.webRTCIceServers)
        self.peer?.delegate = self
        self.peer?.offer(completion: { (sdp, error)  in
            
            if let error = error {
                print("Error creating the offer: \(error)")
                return
            }
            
            guard let sdp = sdp else {
                return
            }
            print("Offer compleated >> SDP: \(sdp)")
            self.updateCallState(callState: .CONNECTING)
        })
    }

    /**
        This function should be called when the remote SDP is inside the  telnyx_rtc.answer message.
        It sets the incoming sdp as the remoteDecription.
        sdp: Is the remote SDP to configure in the current RTCPeerConnection
     */
    func answered(sdp: String) {
        let remoteDescription = RTCSessionDescription(type: .answer, sdp: sdp)
        self.peer?.connection.setRemoteDescription(remoteDescription, completionHandler: { (error) in
            guard let error = error else {
                return
            }
            
            print("Error setting remote description: \(error)")
        })
    }
    
    func incomingOffer(sdp: String) {
        let remoteDescription = RTCSessionDescription(type: .offer, sdp: sdp)
        self.peer?.connection.setRemoteDescription(remoteDescription, completionHandler: { (error) in
            guard let error = error else {
                return
            }
            
            print("Error setting remote description: \(error)")
        })
    }

    /**
     This function should be called to answer an incoming call
     */
    func answerCall() {
        guard let remoteSdp = self.remoteSdp else {
            return
        }
        self.peer = Peer(iceServers: self.config.webRTCIceServers)
        self.peer?.delegate = self
        self.incomingOffer(sdp: remoteSdp)
        self.peer?.answer(completion: { (sdp, error)  in

            if let error = error {
                print("Error creating the answering: \(error)")
                return
            }

            guard let sdp = sdp else {
                return
            }
            print("Answer completed >> SDP: \(sdp)")
            self.updateCallState(callState: .ACTIVE)
        })
    }

    private func updateCallState(callState: CallState) {
        self.callState = callState
        self.delegate?.callStateUpdated(callState: self.callState)
    }
}

// MARK: - PeerDelegate
/**
 Handle Peer events.
 */
extension Call : PeerDelegate {
    
    //If we received at least one ICE Candidate, then we can send the telnyx_rtc.invite message to start a call
    func onICECandidate(sdp: RTCSessionDescription?, iceCandidate: RTCIceCandidate) {
        
        guard let sdp = sdp,
              let sessionId = self.sessionId,
              let callInfo = self.callInfo,
              let callOptions = self.callOptions,
              let _ = self.callInfo?.callId else {
            return
        }
        
        if (self.direction == .OUTBOUND) {
            guard let _ = self.callOptions?.destinationNumber else {
                print("Send invite error  >> NO DESTINATION NUMBER")
                return
            }

            //Build the telnyx_rtc.invite message and send it
            let inviteMessage = InviteMessage(sessionId: sessionId,
                                              sdp: sdp.sdp,
                                              callInfo: callInfo,
                                              callOptions: callOptions)
            
            let message = inviteMessage.encode() ?? ""
            self.socket?.sendMessage(message: message)
            self.updateCallState(callState: .CONNECTING)
            print("Send invite >> \(message)")
        }
    }
}
