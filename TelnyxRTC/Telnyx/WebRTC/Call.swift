//
//  Call.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 03/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation
import WebRTC


/// `CallState` represents the state of the call
public enum CallState {
    /// New call has been created in the client.
    case NEW
    /// The outbound call is being sent to the server.
    case CONNECTING
    /// Call is pending to be answered. Someone is attempting to call you.
    case RINGING
    /// Call is active when two clients are fully connected.
    case ACTIVE
    /// Call has been held.
    case HELD
    /// Call has ended.
    case DONE
}

enum CallDirection : String {
    case INBOUND = "inbound"
    case OUTBOUND = "outbound"
}


protocol CallProtocol: AnyObject {
    func callStateUpdated(call: Call)
}


/// A Call is the representation of an audio or video call between two WebRTC Clients, SIP clients or phone numbers.
/// The call object is created whenever a new call is initiated, either by you or the remote caller.
/// You can access and act upon calls initiated by a remote caller by registering to TxClientDelegate of the TxClient
///
/// ## Examples:
/// ### Create a call:
///
/// ```
///    // Create a client instance
///    self.telnyxClient = TxClient()
///
///    // Asign the delegate to get SDK events
///    self.telnyxClient?.delegate = self
///
///    // Connect the client (Check TxClient class for more info)
///    self.telnyxClient?.connect(....)
///
///    // Create the call and start calling
///    self.currentCall = try self.telnyxClient?.newCall(callerName: "Caller name",
///                                                      callerNumber: "155531234567",
///                                                      // Destination is required and can be a phone number or SIP URI
///                                                      destinationNumber: "18004377950",
///                                                      callId: UUID.init())
/// ```
///
/// ### Answer an incoming call:
/// ```
/// //Init your client
/// func initTelnyxClient() {
///    //
///    self.telnyxClient = TxClient()
///
///    // Asign the delegate to get SDK events
///    self.telnyxClient?.delegate = self
///
///    // Connect the client (Check TxClient class for more info)
///    self.telnyxClient?.connect(....)
/// }
///
/// extension ViewController: TxClientDelegate {
///     //....
///     func onIncomingCall(call: Call) {
///         //We are automatically answering any incoming call as an example, but
///         //maybe you want to store a reference of the call, and answer the call after a button press.
///         self.myCall = call.answer()
///     }
/// }
/// ```
public class Call {

    var direction: CallDirection = .OUTBOUND
    var peer: Peer?
    weak var socket: Socket?
    weak var delegate: CallProtocol?
    var iceServers: [RTCIceServer]

    var remoteSdp: String?
    var callOptions: TxCallOptions?

    /// The Session ID of the current connection
    public internal(set) var sessionId: String?
    /// Telnyx call session ID.
    public internal(set) var telnyxSessionId: UUID?
    /// Telnyx call leg ID
    public internal(set) var telnyxLegId: UUID?

    // MARK: - Properties
    /// `TxCallInfo` Contains the required information of the current Call.
    public var callInfo: TxCallInfo?
    /// `CallState` The actual state of the Call.
    public var callState: CallState = .NEW

    private var ringTonePlayer: AVAudioPlayer?
    private var ringbackPlayer: AVAudioPlayer?

    // MARK: - Initializers
    /// Constructor for incoming calls
    init(callId: UUID,
         remoteSdp: String,
         sessionId: String,
         socket: Socket,
         delegate: CallProtocol,
         telnyxSessionId: UUID? = nil,
         telnyxLegId: UUID? = nil,
         ringtone: String? = nil,
         ringbackTone: String? = nil,
         iceServers: [RTCIceServer]) {
        self.direction = CallDirection.INBOUND
        //Session obtained after login with the signaling socket
        self.sessionId = sessionId
        //this is the signaling server socket
        self.socket = socket

        self.telnyxSessionId = telnyxSessionId
        self.telnyxLegId = telnyxLegId

        self.remoteSdp = remoteSdp
        self.callInfo = TxCallInfo(callId: callId)
        self.delegate = delegate

        // Configure iceServers
        self.iceServers = iceServers

        //Ringtone and ringbacktone
        self.ringTonePlayer = self.buildAudioPlayer(fileName: ringtone)
        self.ringbackPlayer = self.buildAudioPlayer(fileName: ringbackTone)

        self.playRingtone()

        updateCallState(callState: .NEW)
    }

    /// Constructor for outgoing calls
    init(callId: UUID,
         sessionId: String,
         socket: Socket,
         delegate: CallProtocol,
         ringtone: String? = nil,
         ringbackTone: String? = nil,
         iceServers: [RTCIceServer]) {
        //Session obtained after login with the signaling socket
        self.sessionId = sessionId
        //this is the signaling server socket
        self.socket = socket
        self.callInfo = TxCallInfo(callId: callId)
        self.delegate = delegate

        // Configure iceServers
        self.iceServers = iceServers

        //Ringtone and ringbacktone
        self.ringTonePlayer = self.buildAudioPlayer(fileName: ringtone)
        self.ringbackPlayer = self.buildAudioPlayer(fileName: ringbackTone)

        self.updateCallState(callState: .RINGING)
    }

    // MARK: - Private functions
    /**
        Creates an offer to start the calling process
     */
    private func invite(callerName: String, callerNumber: String, destinationNumber: String, clientState: String? = nil) {
        self.direction = .OUTBOUND
        
        self.callInfo?.callerName = callerName
        self.callInfo?.callerNumber = callerNumber
        self.callOptions = TxCallOptions(destinationNumber: destinationNumber,
                                         clientState: clientState)

        self.peer = Peer(iceServers: self.iceServers)
        self.peer?.delegate = self
        self.peer?.offer(completion: { (sdp, error)  in
            
            if let error = error {
                Logger.log.i(message: "Call:: Error creating the offer: \(error)")
                return
            }
            
            guard let sdp = sdp else {
                return
            }
            Logger.log.i(message: "Call:: Offer completed >> SDP: \(sdp)")
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
            if let error = error  {
                Logger.log.e(message: "Call:: Error setting remote description: \(error)")
                return
            }
            
            self.updateCallState(callState: .ACTIVE)
            Logger.log.e(message: "Call:: connected")
        })
    }

    //TODO: We can move this inside the answer() function of the Peer class
    private func incomingOffer(sdp: String) {
        let remoteDescription = RTCSessionDescription(type: .offer, sdp: sdp)
        self.peer?.connection.setRemoteDescription(remoteDescription, completionHandler: { (error) in
            guard let error = error else {
                return
            }
            Logger.log.e(message: "Call:: Error setting remote description: \(error)")
        })
    }

    private func endCall() {
        self.stopRingtone()
        self.stopRingbackTone()
        self.peer?.dispose()
        self.updateCallState(callState: .DONE)
    }

    private func updateCallState(callState: CallState) {
        debugPrint("Call State: \(callState)")
        self.callState = callState
        self.delegate?.callStateUpdated(call: self)
    }
} // End Call class

// MARK: - Call handling
extension Call {

    /// Creates a new oubound call
    internal func newCall(callerName: String,
                 callerNumber: String,
                 destinationNumber: String,
                 clientState: String? = nil) {
        if (destinationNumber.isEmpty) {
            Logger.log.e(message: "Call:: Please enter a destination number.")
            return
        }
        invite(callerName: callerName, callerNumber: callerNumber, destinationNumber: destinationNumber, clientState: clientState)
    }

    /// Hangup or reject an incoming call.
    /// ### Example:
    ///     call.hangup()
    public func hangup() {
        Logger.log.i(message: "Call:: hangup()")
        guard let sessionId = self.sessionId, let callId = self.callInfo?.callId else { return }
        let byeMessage = ByeMessage(sessionId: sessionId, callId: callId.uuidString, causeCode: .USER_BUSY)
        let message = byeMessage.encode() ?? ""
        self.socket?.sendMessage(message: message)
        self.endCall()
    }

    /// Starts the process to answer the incoming call.
    /// ### Example:
    ///     call.answer()
    public func answer() {
        self.stopRingtone()
        self.stopRingbackTone()
        //TODO: Create an error if there's no remote SDP
        guard let remoteSdp = self.remoteSdp else {
            return
        }
        self.peer = Peer(iceServers: self.iceServers)
        self.peer?.delegate = self
        self.incomingOffer(sdp: remoteSdp)
        self.peer?.answer(completion: { (sdp, error)  in

            if let error = error {
                Logger.log.e(message: "Call:: Error creating the answering: \(error)")
                return
            }

            guard let sdp = sdp else {
                return
            }
            Logger.log.i(message: "Call:: Answer completed >> SDP: \(sdp)")
            self.updateCallState(callState: .ACTIVE)
        })
    }
}

// MARK: - DTMF
extension Call {

    /// Sends dual-tone multi-frequency (DTMF) signal
    /// - Parameter dtmf: Single DTMF key
    /// ## Examples:
    /// ### Send DTMF signals:
    ///
    /// ```
    ///    currentCall?.dtmf("0")
    ///    currentCall?.dtmf("1")
    ///    currentCall?.dtmf("*")
    ///    currentCall?.dtmf("#")
    /// ```
    public func dtmf(dtmf: String) {
        Logger.log.i(message: "Call:: dtmf() \(dtmf)")
        guard let sessionId = self.sessionId,
              let callInfo = self.callInfo,
              let callOptions = self.callOptions else { return }

        let dtmfMessage = InfoMessage(sessionId: sessionId, dtmf: dtmf, callInfo: callInfo, callOptions: callOptions)
        guard let message = dtmfMessage.encode(),
              let socket = self.socket else { return }
        socket.sendMessage(message: message)
        Logger.log.s(message: "Call:: dtmf() \(dtmf)")
    }
}
// MARK: - Audio handling
extension Call {
    
    /// Turns off audio output, i.e. makes it so other call participants cannot hear your audio.
    /// ### Example:
    ///     call.muteAudio()
    public func muteAudio() {
        Logger.log.i(message: "Call:: muteAudio()")
        self.peer?.muteUnmuteAudio(mute: true)
    }

    /// Turns on audio output, i.e. makes it so other call participants can hear your audio.
    /// ### Example:
    ///     call.unmuteAudio()
    public func unmuteAudio() {
        Logger.log.i(message: "Call:: unmuteAudio()")
        self.peer?.muteUnmuteAudio(mute: false)
    }
}

// MARK: - Hold / Unhold handling
extension Call {

    /// Holds the call.
    /// ### Example:
    ///     call.hold()
    public func hold() {
        Logger.log.i(message: "Call:: hold()")
        guard let callId = self.callInfo?.callId,
              let sessionId = self.sessionId else { return }
        let hold = ModifyMessage(sessionId: sessionId, callId: callId.uuidString, action: .HOLD)
        let message = hold.encode() ?? ""
        self.socket?.sendMessage(message: message)
        self.updateCallState(callState: .HELD)
        Logger.log.s(message: "Call:: hold()")
    }

    /// Removes hold from the call.
    /// ### Example:
    ///     call.unhold()
    public func unhold() {
        Logger.log.i(message: "Call:: unhold()")
        guard let callId = self.callInfo?.callId,
              let sessionId = self.sessionId else { return }
        let unhold = ModifyMessage(sessionId: sessionId, callId: callId.uuidString, action: .UNHOLD)
        let message = unhold.encode() ?? ""
        self.socket?.sendMessage(message: message)
        self.updateCallState(callState: .ACTIVE)
        Logger.log.s(message: "Call:: unhold()")
    }

    /// Toggles between `active` and `held`  state of the call.
    /// ### Example:
    ///     call.toggleHold()
    public func toggleHold() {
        Logger.log.i(message: "Call:: toggleHold()")
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
        Logger.log.s(message: "Call:: toggleHold()")
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
            Logger.log.e(message: "Call:: onICECandidate missing arguments")
            return
        }
        
        if (self.direction == .OUTBOUND) {
            guard let _ = self.callOptions?.destinationNumber else {
                Logger.log.e(message: "Send invite error  >> NO DESTINATION NUMBER")
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
            Logger.log.s(message: "Call:: Send invite >> \(message)")
        } else {
            //Build the telnyx_rtc.answer message and send it
            let answerMessage = AnswerMessage(sessionId: sessionId, sdp: sdp.sdp, callInfo: callInfo, callOptions: callOptions)
            let message = answerMessage.encode() ?? ""
            self.socket?.sendMessage(message: message)
            self.updateCallState(callState: .ACTIVE)
            Logger.log.s(message:"Send answer >> \(answerMessage)")
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
            self.stopRingtone()
            self.stopRingbackTone()
            //Whenever we place a call from a client and the "Generate ring back tone" is enabled in the portal,
            //the Telnyx Cloud sends the telnyx_rtc.media Verto signaling message with an SDP.
            //The incoming SDP must be set in the caller client as the remote SDP to start listening a ringback tone
            //that is sent from the Telnyx cloud.
            if let params = message.params {
                guard let remoteSdp = params["sdp"] as? String else {
                    Logger.log.w(message: "Call:: .MEDIA missing SDP")
                    return
                }
                self.answered(sdp: remoteSdp)
            }
            //TODO: handle error when there's no SDP
            break

        case .ANSWER:
            self.stopRingtone()
            self.stopRingbackTone()
            //When the remote peer answers the call
            //Set the remote SDP into the current RTCPConnection and the call should start!
            if let params = message.params {
                guard let remoteSdp = params["sdp"] as? String else {
                    Logger.log.w(message: "Call:: .ANSWER missing SDP")
                    return
                }
                //retrieve the remote SDP from the ANSWER verto message and set it to the current RTCPconnection
                self.answered(sdp: remoteSdp)
            }
            //TODO: handle error when there's no sdp
            break;

        case .RINGING:

            if let params = message.params {
                if let telnyxSessionId = params["telnyx_session_id"] as? String,
                   let telnyxSessionUUID = UUID(uuidString: telnyxSessionId) {
                    self.telnyxSessionId = telnyxSessionUUID
                } else {
                    Logger.log.w(message: "Call:: Telnyx Session ID unavailable on RINGING message")
                }

                if let telnyxLegId = params["telnyx_leg_id"] as? String,
                   let telnyxLegIdUUID = UUID(uuidString: telnyxLegId) {
                    self.telnyxLegId = telnyxLegIdUUID
                } else {
                    Logger.log.w(message: "Call:: Telnyx Leg ID unavailable on RINGING message")
                }
            }
            self.playRingbackTone()
            break
        default:
            Logger.log.w(message: "TxClient:: SocketDelegate Default method")
            break
        }
    }
}

// MARK: - Ringtone and Ringback tone handling
extension Call {

    private func playRingtone() {
        Logger.log.i(message: "Call:: playRingtone()")
        guard let ringtonePlayer = self.ringTonePlayer else { return  }

        ringtonePlayer.numberOfLoops = -1 // infinite
        ringtonePlayer.play()
    }

    private func stopRingtone() {
        Logger.log.i(message: "Call:: stopRingtone()")
        self.ringTonePlayer?.stop()
    }

    private func playRingbackTone() {
        Logger.log.i(message: "Call:: playRingbackTone()")
        guard let ringbackPlayer = self.ringbackPlayer else { return  }

        ringbackPlayer.numberOfLoops = -1 // infinite
        ringbackPlayer.play()
    }

    private func stopRingbackTone() {
        Logger.log.i(message: "Call:: stopRingbackTone()")
        self.ringbackPlayer?.stop()
    }

    private func buildAudioPlayer(fileName: String?) -> AVAudioPlayer? {
        guard let file = fileName,
              let path = Bundle.main.path(forResource: file, ofType: nil ) else {
            Logger.log.w(message: "Call:: buildAudioPlayer() file not found: \(fileName ?? "Unknown").")
            return nil
        }
        let url = URL(fileURLWithPath: path)
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient)
            try AVAudioSession.sharedInstance().setActive(true)
            return audioPlayer
        } catch{
            Logger.log.e(message: "Call:: buildAudioPlayer() error: \(error)")
        }
        return nil
    }
}
