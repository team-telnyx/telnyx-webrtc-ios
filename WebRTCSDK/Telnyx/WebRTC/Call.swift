//
//  Call.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 03/03/2021.
//

import Foundation
import WebRTC


/// `CallState` possible call states
public enum CallState {
    /// Call is created
    case NEW
    /// Call is been connected to the remote client.
    case CONNECTING
    /// Call is pending to be answered.
    case RINGING
    /// Call is active when two clients are fully connected.
    case ACTIVE
    /// User has held the call
    case HELD
    /// When the call has  ended
    case DONE
}

enum CallDirection : String {
    case INBOUND = "inbound"
    case OUTBOUND = "outbound"
}


protocol CallProtocol {
    func callStateUpdated(call: Call)
}

public class Call {

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

    private var ringTonePlayer: AVAudioPlayer?
    private var ringbackPlayer: AVAudioPlayer?

    init(callId: UUID,
         remoteSdp: String,
         sessionId: String,
         socket: Socket,
         delegate: CallProtocol,
         ringtone: String? = nil,
         ringbackTone: String? = nil) {
        self.direction = CallDirection.INBOUND
        //Session obtained after login with the signaling socket
        self.sessionId = sessionId
        //this is the signaling server socket
        self.socket = socket

        self.remoteSdp = remoteSdp
        self.callInfo = TxCallInfo(callId: callId)
        self.delegate = delegate

        //Ringtone and ringbacktone
        self.ringTonePlayer = self.buildAudioPlayer(fileName: ringtone)
        self.ringbackPlayer = self.buildAudioPlayer(fileName: ringbackTone)

        self.playRingtone()
        updateCallState(callState: .NEW)
    }

    init(callId: UUID,
         sessionId: String,
         socket: Socket,
         delegate: CallProtocol,
         ringtone: String? = nil,
         ringbackTone: String? = nil) {
        //Session obtained after login with the signaling socket
        self.sessionId = sessionId
        //this is the signaling server socket
        self.socket = socket
        self.callInfo = TxCallInfo(callId: callId)
        self.delegate = delegate

        //Ringtone and ringbacktone
        self.ringTonePlayer = self.buildAudioPlayer(fileName: ringtone)
        self.ringbackPlayer = self.buildAudioPlayer(fileName: ringbackTone)

        self.updateCallState(callState: .RINGING)
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
    private func answered(sdp: String) {
        let remoteDescription = RTCSessionDescription(type: .answer, sdp: sdp)
        self.peer?.connection.setRemoteDescription(remoteDescription, completionHandler: { (error) in
            guard let error = error else {
                return
            }
            
            print("Error setting remote description: \(error)")
        })
    }

    //TODO: We can move this inside the answer() function of the Peer class
    private func incomingOffer(sdp: String) {
        let remoteDescription = RTCSessionDescription(type: .offer, sdp: sdp)
        self.peer?.connection.setRemoteDescription(remoteDescription, completionHandler: { (error) in
            guard let error = error else {
                return
            }
            print("Error setting remote description: \(error)")
        })
    }

    private func endCall() {
        self.stopRingtone()
        self.stopRingbackTone()
        self.peer?.dispose()
        self.updateCallState(callState: .DONE)
    }

    private func updateCallState(callState: CallState) {
        self.callState = callState
        self.delegate?.callStateUpdated(call: self)
    }
}
// MARK: - Call handling
extension Call {
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
     Sends a telnyx rtc.bye message through the socket
     */
    func hangup() {
        guard let sessionId = self.sessionId, let callId = self.callInfo?.callId else { return }
        let byeMessage = ByeMessage(sessionId: sessionId, callId: callId.uuidString, causeCode: .USER_BUSY)
        let message = byeMessage.encode() ?? ""
        self.socket?.sendMessage(message: message)
        self.endCall()
    }

    /**
     This function should be called to answer an incoming call
     */
    func answer() {
        self.stopRingtone()
        //TODO: Create an error if there's no remote SDP
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
}
// MARK: - Audio handling
extension Call {
    
    func muteAudio() {
        self.peer?.muteUnmuteAudio(mute: true)
    }
    
    func unmuteAudio() {
        self.peer?.muteUnmuteAudio(mute: false)
    }
}

// MARK: - Hold / Unhold functions
extension Call {

    func hold() {
        guard let callId = self.callInfo?.callId,
              let sessionId = self.sessionId else { return }
        let hold = ModifyMessage(sessionId: sessionId, callId: callId.uuidString, action: .HOLD)
        let message = hold.encode() ?? ""
        self.socket?.sendMessage(message: message)
        self.updateCallState(callState: .HELD)
    }

    func unhold() {
        guard let callId = self.callInfo?.callId,
              let sessionId = self.sessionId else { return }
        let unhold = ModifyMessage(sessionId: sessionId, callId: callId.uuidString, action: .UNHOLD)
        let message = unhold.encode() ?? ""
        self.socket?.sendMessage(message: message)
        self.updateCallState(callState: .ACTIVE)
    }

    func toggleHold() {
        guard let callId = self.callInfo?.callId,
              let sessionId = self.sessionId else { return }
        let toggleHold = ModifyMessage(sessionId: sessionId, callId: callId.uuidString, action: .TOGGLE_HOLD)
        let message = toggleHold.encode() ?? ""
        self.socket?.sendMessage(message: message)

        if (self.callState == .ACTIVE) {
            self.updateCallState(callState: .HELD)
        } else {
            self.updateCallState(callState: .ACTIVE)
        }
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
        } else {
            //Build the telnyx_rtc.answer message and send it
            let answerMessage = AnswerMessage(sessionId: sessionId, sdp: sdp.sdp, callInfo: callInfo, callOptions: callOptions)
            let message = answerMessage.encode() ?? ""
            self.socket?.sendMessage(message: message)
            self.updateCallState(callState: .ACTIVE)
            print("Send answer >> \(answerMessage)")
        }
    }
}

// MARK: - Hanlde Verto Messages
/**
 Handle verto messages
 */
extension Call {

    internal func handleVertoMessage(message: Message) {

        switch message.method {
        case .BYE:
            //Close call
            self.endCall()
            break

        case .MEDIA:
            //Whenever we place a call from a client and the "Generate ring back tone" is enabled in the portal,
            //the Telnyx Cloud sends the telnyx_rtc.media Verto signaling message with an SDP.
            //The incoming SDP must be set in the caller client as the remote SDP to start listening a ringback tone
            //that is sent from the Telnyx cloud.
            if let params = message.params {
                guard let remoteSdp = params["sdp"] as? String else {
                    return
                }
                self.answered(sdp: remoteSdp)
            }
            //TODO: handle error when there's no SDP
            break

        case .ANSWER:
            //When the remote peer answers the call
            //Set the remote SDP into the current RTCPConnection and the call should start!
            if let params = message.params {
                guard let remoteSdp = params["sdp"] as? String else {
                    return
                }
                //retrieve the remote SDP from the ANSWER verto message and set it to the current RTCPconnection
                self.answered(sdp: remoteSdp)
            }
            self.stopRingtone()
            self.stopRingbackTone()
            //TODO: handle error when there's no sdp
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

// MARK: - Ringtone and Ringback tone handling
extension Call {

    private func playRingtone() {
        print("TxClient:: playRingtone()")
        guard let ringtonePlayer = self.ringTonePlayer else { return  }

        ringtonePlayer.numberOfLoops = -1 // infinite
        ringtonePlayer.play()
    }

    private func stopRingtone() {
        print("Call:: stopRingtone()")
        self.ringTonePlayer?.stop()
    }

    private func playRingbackTone() {
        print("Call:: playRingbackTone()")
        guard let ringbackPlayer = self.ringbackPlayer else { return  }

        ringbackPlayer.numberOfLoops = -1 // infinite
        ringbackPlayer.play()
    }

    private func stopRingbackTone() {
        print("Call:: stopRingbackTone()")
        self.ringbackPlayer?.stop()
    }

    private func buildAudioPlayer(fileName: String?) -> AVAudioPlayer? {
        guard let file = fileName,
              let path = Bundle.main.path(forResource: file, ofType: nil ) else {
            print("Call:: buildAudioPlayer() file not found: \(fileName ?? "Unknown").")
            return nil
        }
        let url = URL(fileURLWithPath: path)
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient)
            try AVAudioSession.sharedInstance().setActive(true)
            return audioPlayer
        } catch{
            print("Call:: buildAudioPlayer() error: \(error)")
        }
        return nil
    }
}
