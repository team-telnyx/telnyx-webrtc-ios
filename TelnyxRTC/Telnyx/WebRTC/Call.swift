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


/// A Call represents an audio or video communication session between two endpoints: WebRTC Clients, SIP clients, or phone numbers.
/// The Call object manages the entire lifecycle of a call, from initiation to termination, handling both outbound and inbound calls.
///
/// A Call object is created in two scenarios:
/// 1. When you initiate a new outbound call using TxClient's newCall method
/// 2. When you receive an inbound call through the TxClientDelegate's onIncomingCall callback
///
/// ## Key Features
/// - Audio and video call support
/// - Call state management (NEW, CONNECTING, RINGING, ACTIVE, HELD, DONE)
/// - Mute/unmute functionality
/// - DTMF tone sending
/// - Custom headers support for both INVITE and ANSWER messages
/// - Call statistics reporting when debug mode is enabled
///
/// ## Examples
/// ### Creating an Outbound Call:
/// ```swift
///    // Initialize the client
///    self.telnyxClient = TxClient()
///    self.telnyxClient?.delegate = self
///
///    // Connect the client (see TxClient documentation for connection options)
///    self.telnyxClient?.connect(....)
///
///    // Create and initiate a call
///    self.currentCall = try self.telnyxClient?.newCall(
///        callerName: "John Doe",           // The name to display for the caller
///        callerNumber: "155531234567",     // The caller's phone number
///        destinationNumber: "18004377950", // The target phone number or SIP URI
///        callId: UUID.init(),              // Unique identifier for the call
///        clientState: nil,                 // Optional client state information
///        customHeaders: [:]                // Optional custom SIP headers
///    )
/// ```
///
/// ### Handling an Incoming Call:
/// ```swift
/// class CallHandler: TxClientDelegate {
///     var activeCall: Call?
///
///     func initTelnyxClient() {
///         let client = TxClient()
///         client.delegate = self
///         client.connect(....)
///     }
///
///     func onIncomingCall(call: Call) {
///         // Store the call reference
///         self.activeCall = call
///
///         // Option 1: Auto-answer the call
///         call.answer()
///
///         // Option 2: Answer with custom headers
///         call.answer(customHeaders: ["X-Custom-Header": "Value"])
///
///         // Option 3: Reject the call
///         // call.hangup()
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

    /// Custom headers received from the WebRTC INVITE message.
    /// These headers are passed during call initiation and can contain application-specific information.
    /// Format should be ["X-Header-Name": "Value"] where header names must start with "X-".
    public internal(set) var inviteCustomHeaders: [String:String]?
    
    /// Custom headers received from the WebRTC ANSWER message.
    /// These headers are passed during call acceptance and can contain application-specific information.
    /// Format should be ["X-Header-Name": "Value"] where header names must start with "X-".
    public internal(set) var answerCustomHeaders: [String:String]?
    
    /// The unique session identifier for the current WebRTC connection.
    /// This ID is established during client connection and remains constant for the session duration.
    public internal(set) var sessionId: String?
    
    /// The unique Telnyx session identifier for this call.
    /// This ID can be used to track the call in Telnyx's systems and logs.
    public internal(set) var telnyxSessionId: UUID?
    
    /// The unique Telnyx leg identifier for this call.
    /// A call can have multiple legs (e.g., in call transfers). This ID identifies this specific leg.
    public internal(set) var telnyxLegId: UUID?
    
    /// Enables WebRTC statistics reporting for debugging purposes.
    /// When true, the SDK will collect and send WebRTC statistics to Telnyx servers.
    /// This is useful for troubleshooting call quality issues.
    public internal(set) var debug: Bool = false
    
    /// Controls whether the SDK should force TURN relay for peer connections.
    /// When enabled, the SDK will only use TURN relay candidates for ICE gathering,
    /// which prevents the "local network access" permission popup from appearing.
    public internal(set) var forceRelayCandidate: Bool = false


    // MARK: - Properties
    /// Contains essential information about the current call including:
    /// - callId: Unique identifier for this call
    /// - callerName: Display name of the caller
    /// - callerNumber: Phone number or SIP URI of the caller
    /// See `TxCallInfo` for complete details.
    public var callInfo: TxCallInfo?
    
    /// The current state of the call. Possible values:
    /// - NEW: Call object created but not yet initiated
    /// - CONNECTING: Outbound call is being established
    /// - RINGING: Incoming call waiting to be answered
    /// - ACTIVE: Call is connected and media is flowing
    /// - HELD: Call is temporarily suspended
    /// - DONE: Call has ended
    ///
    /// The state changes are notified through the `CallProtocol` delegate.
    public var callState: CallState = .NEW
    
    /// Indicates whether the local audio is currently muted.
    /// - Returns: `true` if the call is muted (audio track disabled)
    /// - Returns: `false` if the call is not muted (audio track enabled)
    ///
    /// Use `muteAudio()` and `unmuteAudio()` to change the mute state.
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
         debug: Bool = false,
         forceRelayCandidate: Bool = false
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
        self.forceRelayCandidate = forceRelayCandidate
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
         debug: Bool = false,
         forceRelayCandidate: Bool = false) {
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
        self.forceRelayCandidate = forceRelayCandidate
    }

    /// Constructor for outgoing calls
    init(callId: UUID,
         sessionId: String,
         socket: Socket,
         delegate: CallProtocol,
         ringtone: String? = nil,
         ringbackTone: String? = nil,
         iceServers: [RTCIceServer],
         debug: Bool = false,
         forceRelayCandidate: Bool = false) {
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
        self.forceRelayCandidate = forceRelayCandidate
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
        self.peer = Peer(iceServers: self.iceServers, forceRelayCandidate: self.forceRelayCandidate)
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
        self.peer = Peer(iceServers: self.iceServers, forceRelayCandidate: self.forceRelayCandidate)
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
        self.peer = Peer(iceServers: self.iceServers, isAttach: true, forceRelayCandidate: self.forceRelayCandidate)
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

    /// Sends a DTMF (Dual-Tone Multi-Frequency) signal during an active call.
    /// DTMF signals are used to send digits and symbols over a phone line, typically
    /// for interacting with automated systems, voicemail, or IVR menus.
    ///
    /// - Parameter dtmf: A string containing a single DTMF character. Valid characters are:
    ///   - Digits: 0-9
    ///   - Special characters: * (asterisk), # (pound)
    ///   - Letters: A-D (less commonly used)
    ///
    /// ## Examples:
    /// ```swift
    /// // Navigate an IVR menu
    /// currentCall?.dtmf("1")    // Select option 1
    /// currentCall?.dtmf("0")    // Select option 0
    ///
    /// // Special characters
    /// currentCall?.dtmf("*")    // Send asterisk
    /// currentCall?.dtmf("#")    // Send pound/hash
    /// ```
    ///
    /// Note: The call must be in ACTIVE state for DTMF signals to be sent successfully.
    /// Each DTMF tone should be sent individually with appropriate timing between tones
    /// when sending multiple digits.
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
