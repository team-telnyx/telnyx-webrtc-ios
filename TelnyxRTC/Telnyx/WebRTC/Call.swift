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
    case ATTACH = "attach"
}

enum SoundFileType : String {
    case RINGTONE = "ringtone"
    case RINGBACK = "ringback"
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
    
    var statsReporter: WebRTCStatsReporter?

    /// Custum headers pased /from webrtc telnyx_rtc.INVITE Messages
    public internal(set) var inviteCustomHeaders: [String:String]?
    
    /// Custum headers pased tfrom telnyx_rtc.ANSWER webrtcMessages
    public internal(set) var answerCustomHeaders: [String:String]?
    
    /// The Session ID of the current connection
    public internal(set) var sessionId: String?
    /// Telnyx call session ID.
    public internal(set) var telnyxSessionId: UUID?
    /// Telnyx call leg ID
    public internal(set) var telnyxLegId: UUID?
    /// To enable call stats
    public internal(set) var debug: Bool = false


    // MARK: - Properties
    /// `TxCallInfo` Contains the required information of the current Call.
    public var callInfo: TxCallInfo?
    /// `CallState` The actual state of the Call.
    public var callState: CallState = .NEW
    
    /// `isMuted` Indicates if the call audio is muted based on the peer's audio track state.
    public var isMuted: Bool {
        return !(peer?.isAudioTrackEnabled ?? false)
    }

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
         iceServers: [RTCIceServer],
         isAttach: Bool = false,
         debug: Bool = false
    ) {
        if isAttach {
            self.direction = CallDirection.ATTACH
        } else {
            self.direction = CallDirection.INBOUND
        }
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

        if !isAttach {
            //Ringtone and ringbacktone
            self.ringTonePlayer = self.buildAudioPlayer(fileName: ringtone,fileType: .RINGTONE)
            self.ringbackPlayer = self.buildAudioPlayer(fileName: ringbackTone,fileType: .RINGBACK)

            self.playRingtone()
        }
      
        if !isAttach {
            updateCallState(callState: .NEW)
        }
        
        self.debug = debug
    }
    
    //Contructor for attachCalls
    init(callId: UUID,
         remoteSdp: String,
         sessionId: String,
         socket: Socket,
         delegate: CallProtocol,
         telnyxSessionId: UUID? = nil,
         telnyxLegId: UUID? = nil,
         iceServers: [RTCIceServer],
         debug: Bool = false) {
        self.direction = CallDirection.ATTACH
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
        
        self.debug = debug
    }

    /// Constructor for outgoing calls
    init(callId: UUID,
         sessionId: String,
         socket: Socket,
         delegate: CallProtocol,
         ringtone: String? = nil,
         ringbackTone: String? = nil,
         iceServers: [RTCIceServer],
         debug: Bool = false) {
        //Session obtained after login with the signaling socket
        self.sessionId = sessionId
        //this is the signaling server socket
        self.socket = socket
        self.callInfo = TxCallInfo(callId: callId)
        self.delegate = delegate

        // Configure iceServers
        self.iceServers = iceServers

        //Ringtone and ringbacktone
        self.ringTonePlayer = self.buildAudioPlayer(fileName: ringtone,fileType: .RINGTONE)
        self.ringbackPlayer = self.buildAudioPlayer(fileName: ringbackTone,fileType: .RINGBACK)

        self.updateCallState(callState: .RINGING)
        self.debug = debug
    }

    // MARK: - Private functions
    /**
        Creates an offer to start the calling process
     */
    private func invite(callerName: String, callerNumber: String, destinationNumber: String, clientState: String? = nil,
                        customHeaders:[String:String] = [:]) {
        self.direction = .OUTBOUND
        self.inviteCustomHeaders = customHeaders
        self.callInfo?.callerName = callerName
        self.callInfo?.callerNumber = callerNumber
        self.callOptions = TxCallOptions(destinationNumber: destinationNumber,
                                         clientState: clientState)

        // We need to:
        // - Create the reporter to send the startReporting message before creating the peer connection
        // - Start the reporter once the peer connection is created
        self.configureStatsReporter()
        self.peer = Peer(iceServers: self.iceServers)
        self.startStatsReporter()
        self.peer?.delegate = self
        self.peer?.socket = self.socket
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
    private func answered(sdp: String, custumHeaders:[String:String] = [:]) {
        let remoteDescription = RTCSessionDescription(type: .answer, sdp: sdp)
        self.peer?.connection?.setRemoteDescription(remoteDescription, completionHandler: { (error) in
            if let error = error  {
                Logger.log.e(message: "Call:: Error setting remote description: \(error)")
                return
            }
            self.answerCustomHeaders = custumHeaders
            self.updateCallState(callState: .ACTIVE)
            Logger.log.e(message: "Call:: connected")
        })
    }
    
    /**
        This function should be called when the remote SDP is inside the  telnyx_rtc.media message.
        It sets the incoming sdp as the remoteDecription.
        sdp: Is the remote SDP to configure in the current RTCPeerConnection
     */
    private func streamMedia(sdp: String) {
        let remoteDescription = RTCSessionDescription(type: .prAnswer, sdp: sdp)
        self.peer?.connection?.setRemoteDescription(remoteDescription, completionHandler: { (error) in
            if let error = error  {
                Logger.log.e(message: "Call:: Error setting remote description: \(error)")
                return
            }
            
            Logger.log.i(message: "Call:: Media Streaming")
        })
    }

    //TODO: We can move this inside the answer() function of the Peer class
    private func incomingOffer(sdp: String) {
        let remoteDescription = RTCSessionDescription(type: .offer, sdp: sdp)
        self.peer?.connection?.setRemoteDescription(remoteDescription, completionHandler: { (error) in
            guard let error = error else {
                return
            }
            Logger.log.e(message: "Call:: Error setting remote description: \(error)")
        })
    }

    private func endCall() {
        self.stopRingtone()
        self.stopRingbackTone()
        self.statsReporter?.dispose()
        self.peer?.dispose()
        self.updateCallState(callState: .DONE)
    }
    
    internal func endForAttachCall() {
        self.statsReporter?.dispose()
        self.peer?.dispose()
       // self.updateCallState(callState: .DONE)
    }

    private func updateCallState(callState: CallState) {
        Logger.log.i(message: "Call state updated: \(callState)")
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
                          clientState: String? = nil,
                          customHeaders:[String:String] = [:]) {
        if (destinationNumber.isEmpty) {
            Logger.log.e(message: "Call:: Please enter a destination number.")
            return
        }
        invite(callerName: callerName, callerNumber: callerNumber, destinationNumber: destinationNumber, clientState: clientState, customHeaders: customHeaders)
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
    ///  - Parameters:
    ///         - customHeaders: (optional) Custom Headers to be passed over webRTC Messages, should be in the
    ///     format `X-key:Value` `X` is required for headers to be passed.
    public func answer(customHeaders:[String:String] = [:]) {
        self.stopRingtone()
        self.stopRingbackTone()
        //TODO: Create an error if there's no remote SDP
        guard let remoteSdp = self.remoteSdp else {
            return
        }
        self.answerCustomHeaders = customHeaders
        self.configureStatsReporter()
        self.peer = Peer(iceServers: self.iceServers)
        self.startStatsReporter()
        self.peer?.delegate = self
        self.peer?.socket = self.socket
        self.incomingOffer(sdp: remoteSdp)
        self.peer?.answer(callLegId: self.telnyxLegId?.uuidString ?? "",completion: { (sdp, error)  in

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
    
    
    /// Starts the process to answer the incoming call.
    /// ### Example:
    ///     call.answer()
    ///  - Parameters:
    ///         - customHeaders: (optional) Custom Headers to be passed over webRTC Messages, should be in the
    ///     format `X-key:Value` `X` is required for headers to be passed.
    internal func acceptReAttach(peer: Peer?, customHeaders:[String:String] = [:]) {
        //TODO: Create an error if there's no remote SDP
        guard let remoteSdp = self.remoteSdp else {
            return
        }
        peer?.dispose()
        self.statsReporter?.dispose()
        self.answerCustomHeaders = customHeaders
        self.configureStatsReporter()
        self.peer = Peer(iceServers: self.iceServers, isAttach: true)
        self.startStatsReporter()
        self.peer?.delegate = self
        self.peer?.socket = self.socket
        self.incomingOffer(sdp: remoteSdp)
        self.peer?.answer(callLegId: self.telnyxLegId?.uuidString ?? "",completion: { (sdp, error)  in

            if let error = error {
                Logger.log.e(message: "Call:: Error creating the answering: \(error)")
                return
            }

            guard let sdp = sdp else {
                return
            }
            Logger.log.i(message: "Call:: Attach completed >> SDP: \(sdp)")
            //self.peer?.startTimer()
            //self.updateCallState(callState: .ACTIVE)
        })
    }
    
    private func configureStatsReporter() {
        if debug,
           let socket = self.socket {
            self.statsReporter?.dispose()
            self.statsReporter = WebRTCStatsReporter(socket: socket)
        }
    }

    private func startStatsReporter() {
        if debug,
           let callId = self.callInfo?.callId,
           let peer = self.peer {
            self.statsReporter?.startDebugReport(peerId: callId, peer: peer)
        }
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
        self.callState = .HELD
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
    func onNegotiationEnded(sdp: RTCSessionDescription?) {
        
        guard let sdp = sdp,
              let sessionId = self.sessionId,
              let callInfo = self.callInfo,
              let callOptions = self.callOptions,
              let _ = self.callInfo?.callId else {
            Logger.log.e(message: "Call:: onNegotiationEnded missing arguments")
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
                                              callOptions: callOptions,
                                              customHeaders: self.inviteCustomHeaders ?? [:])
            
            let message = inviteMessage.encode() ?? ""
            self.socket?.sendMessage(message: message)
            self.updateCallState(callState: .CONNECTING)
            Logger.log.s(message: "Send invite >> \(message)")
        }
        else if (self.direction == .ATTACH) {
            let attachCallOption = TxCallOptions(destinationNumber: callOptions.destinationNumber,attach: true,userVariables: callOptions.userVariables)

            
            let attachMessage = ReAttachMessage(sessionId: sessionId, sdp: sdp.sdp, callInfo: callInfo, callOptions: attachCallOption,
                                              customHeaders: self.answerCustomHeaders ?? [:]
            )
            let message = attachMessage.encode() ?? ""
            self.socket?.sendMessage(message: message)
            self.updateCallState(callState: .ACTIVE)
            Logger.log.s(message:"Send attach >> \(attachMessage)")
        } else {
            //Build the telnyx_rtc.answer message and send it

            let answerMessage = AnswerMessage(sessionId: sessionId, sdp: sdp.sdp, callInfo: callInfo, callOptions: callOptions,
                                              customHeaders: self.answerCustomHeaders ?? [:]
            )
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

    internal func handleVertoMessage(message: Message,dataMessage: String,txClient:TxClient) {

        switch message.method {
        case .BYE:
            //Close call
            self.endCall()
            if(txClient.sendFileLogs){
                FileLogger.shared.log("Call:: BYE \(message)")
                FileLogger.shared.sendLogFile()
                txClient.sendFileLogs = false
            }
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
                self.remoteSdp = remoteSdp
                self.streamMedia(sdp: remoteSdp)
            }
            //TODO: handle error when there's no SDP
            break

        case .ANSWER:
            self.stopRingtone()
            self.stopRingbackTone()
            //When the remote peer answers the call
            //Set the remote SDP into the current RTCPConnection and the call should start!
            if let params = message.params {
                if let remoteSdp = params["sdp"] as? String {
                    self.remoteSdp = remoteSdp
                } else {
                    Logger.log.w(message: "Call:: .ANSWER missing SDP")
                }
                var customHeaders = [String:String]()
                if params["dialogParams"] is [String:Any] {
                    do {
                        
                        let dataDecoded = try JSONDecoder().decode(CustomHeaderData.self, from: dataMessage.data(using: .utf8)!)
                        dataDecoded.params.dialogParams.custom_headers.forEach { xHeader in
                            customHeaders[xHeader.name] = xHeader.value
                        }
                        print("Data Decode : \(dataDecoded)")
                    } catch {
                        print("decoding error: \(error)")
                    }
                }
                //retrieve the remote SDP from the ANSWER verto message and set it to the current RTCPconnection
                self.answered(sdp: self.remoteSdp ?? "",custumHeaders: customHeaders)
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
            self.updateCallState(callState: .RINGING)
            self.playRingbackTone()
            break
        default:
            Logger.log.w(message: "TxClient:: SocketDelegate Default method")
            break
        }
        
        if txClient.isSpeakerEnabled {
            Logger.log.w(message: "Speaker Enabled")
            txClient.setSpeaker()
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

    private func buildAudioPlayer(fileName: String?,fileType:SoundFileType) -> AVAudioPlayer? {
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
            
            Logger.log.e(message: "Call:: buildAudioPlayer() \(fileType.rawValue) error: \(error)")
        }
        return nil
    }
}
