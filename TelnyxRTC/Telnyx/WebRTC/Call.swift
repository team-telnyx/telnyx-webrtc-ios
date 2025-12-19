//
//  Call.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 03/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation
import WebRTC
import AVFoundation


/// Data class to hold detailed reasons for call termination.
public struct CallTerminationReason {
    /// General cause description (e.g., "CALL_REJECTED").
    public let cause: String?
    /// Numerical code for the cause (e.g., 21).
    public let causeCode: Int?
    /// SIP response code (e.g., 403).
    public let sipCode: Int?
    /// SIP reason phrase (e.g., "Dialed number is not included in whitelisted countries").
    public let sipReason: String?
    
    public init(cause: String? = nil, causeCode: Int? = nil, sipCode: Int? = nil, sipReason: String? = nil) {
        self.cause = cause
        self.causeCode = causeCode
        self.sipCode = sipCode
        self.sipReason = sipReason
    }
}

/// `CallState` represents the state of the call
public enum CallState: Equatable {
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
    case DONE(reason: CallTerminationReason? = nil)
    /// The active call is being recovered. Usually after a network switch or bad network
    case RECONNECTING(reason: Reason)
    /// The active call is dropped. Usually when the network is lost.
    case DROPPED(reason: Reason)

    /// Enum to represent reasons for reconnection or call drop.
    public enum Reason: String {
        case networkSwitch = "Network switched"
        case networkLost = "Network lost"
        case serverError = "Server error"
    }

    /// Helper function to get the reason for the state (if applicable).
    public func getReason() -> String? {
        switch self {
        case let .RECONNECTING(reason), let .DROPPED(reason):
            return reason.rawValue
        case let .DONE(terminationReason):
            return terminationReason?.cause
        default:
            return nil
        }
    }
    
    public static func == (lhs: CallState, rhs: CallState) -> Bool {
        switch (lhs, rhs) {
        case (.NEW, .NEW), (.CONNECTING, .CONNECTING), (.RINGING, .RINGING),
             (.ACTIVE, .ACTIVE), (.HELD, .HELD):
            return true
        case let (.DONE(lhsReason), .DONE(rhsReason)):
            // Consider DONE states equal regardless of reason for basic equality checks
            return true
        case let (.RECONNECTING(lhsReason), .RECONNECTING(rhsReason)):
            return lhsReason == rhsReason
        case let (.DROPPED(lhsReason), .DROPPED(rhsReason)):
            return lhsReason == rhsReason
        default:
            return false
        }
    }
}

public extension CallState {
    /// Returns true if the call is considered active (ACTIVE or HELD states)
    var isConsideredActive: Bool {
        switch self {
        case .ACTIVE, .HELD:
            return true
        default:
            return false
        }
    }
    
    /// Returns the string representation of the enum case.
    var value: String {
        switch self {
        case .NEW:
            return "NEW"
        case .CONNECTING:
            return "CONNECTING"
        case .RINGING:
            return "RINGING"
        case .ACTIVE:
            return "ACTIVE"
        case .HELD:
            return "HELD"
        case .DONE(_):
            return "DONE"
        case .RECONNECTING:
            return "RECONNECTING"
        case .DROPPED:
            return "DROPPED"
        }
    }
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
    
    /// Flag to track if we're currently performing ICE restart
    internal var isIceRestarting: Bool = false
    
    /// Flag to track if we need to reset audio after ICE restart
    internal var shouldResetAudioAfterIceRestart: Bool = false
    
    /// Speaker state saved at the time of network change (before iOS can change audio route)
    private var speakerStateAtNetworkChange: Bool? = nil
    
    /// Previous ICE connection state for monitoring transitions
    private var previousIceConnectionState: RTCIceConnectionState = .new

    /// Flag to track if ICE connection has been successfully established at least once
    private var hasBeenConnectedBefore: Bool = false

    /// RTT monitoring variables
    private var isRttMonitoringActive: Bool = false
    private var lastAudioResetTime: Date = Date.distantPast
    private var rttResetTimer: Timer?
    private var currentRttMs: Double = 0.0
    
    /// Callback for real-time call quality metrics
    /// This is triggered whenever new WebRTC statistics are available
    public var onCallQualityChange: ((CallQualityMetrics) -> Void)?

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
    
    /// Enables CallQuality Metrics for Call
    public internal(set) var enableQualityMetrics: Bool = false
    
    /// Controls whether the SDK should send WebRTC statistics via socket to Telnyx servers.
    /// When enabled, collected WebRTC stats will be sent to Telnyx servers for monitoring and debugging.
    /// This is independent of stats collection - stats can be collected without being sent via socket.
    public internal(set) var sendWebRTCStatsViaSocket: Bool = false
    
    /// Controls whether the SDK should use trickle ICE for WebRTC signaling.
    /// When enabled, ICE candidates are sent individually as they are discovered,
    /// rather than waiting for all candidates to be gathered before sending the offer/answer.
    public internal(set) var useTrickleIce: Bool = false
    
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
    
    /// The local media stream containing audio and/or video tracks being sent to the remote party.
    /// This stream represents the media captured from the local device (microphone, camera).
    /// Can be used for audio visualization, local video preview, or other media processing.
    ///
    /// ## Examples
    /// ```swift
    /// // Access local audio tracks for visualization
    /// if let localStream = call.localStream {
    ///     let audioTracks = localStream.audioTracks
    ///     // Use audio tracks for waveform visualization
    /// }
    /// ```
    public var localStream: RTCMediaStream? {
        return peer?.localStream
    }
    
    /// The remote media stream containing audio and/or video tracks received from the remote party.
    /// This stream represents the media being received from the other participant in the call.
    /// Can be used for audio visualization, remote video display, or other media processing.
    ///
    /// ## Examples
    /// ```swift
    /// // Access remote audio tracks for visualization
    /// if let remoteStream = call.remoteStream {
    ///     let audioTracks = remoteStream.audioTracks
    ///     // Use audio tracks for waveform visualization
    /// }
    /// ```
    public var remoteStream: RTCMediaStream? {
        return peer?.remoteStream
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
         forceRelayCandidate: Bool = false,
         enableQualityMetrics: Bool = false,
         sendWebRTCStatsViaSocket: Bool = false,
         useTrickleIce: Bool = false
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
        self.enableQualityMetrics = enableQualityMetrics
        self.sendWebRTCStatsViaSocket = sendWebRTCStatsViaSocket
        self.useTrickleIce = useTrickleIce
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
         forceRelayCandidate: Bool = false,
         sendWebRTCStatsViaSocket: Bool = false,
         useTrickleIce: Bool = false) {
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
        self.sendWebRTCStatsViaSocket = sendWebRTCStatsViaSocket
        self.useTrickleIce = useTrickleIce
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
         forceRelayCandidate: Bool = false,
         useTrickleIce: Bool = false) {
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

        self.updateCallState(callState: .NEW)
        self.debug = debug
        self.forceRelayCandidate = forceRelayCandidate
        self.useTrickleIce = useTrickleIce
    }

    // MARK: - Private functions
    /**
        Creates an offer to start the calling process
     */
    private func invite(callerName: String,
                        callerNumber: String,
                        destinationNumber: String,
                        clientState: String? = nil,
                        customHeaders: [String:String] = [:],
                        preferredCodecs: [TxCodecCapability]? = nil,
                        debug:Bool = false) {
        self.direction = .OUTBOUND
        self.inviteCustomHeaders = customHeaders
        self.callInfo?.callerName = callerName
        self.callInfo?.callerNumber = callerNumber
        self.callOptions = TxCallOptions(destinationNumber: destinationNumber,
                                         clientState: clientState,
                                         preferredCodecs: preferredCodecs)

        self.enableQualityMetrics = debug
        // We need to:
        // - Create the reporter to send the startReporting message before creating the peer connection
        // - Start the reporter once the peer connection is created
        self.configureStatsReporter()
        Logger.log.i(message: "[TRICKLE-ICE] Call:: Creating Peer for outbound call with useTrickleIce = \(self.useTrickleIce)")
        self.peer = Peer(iceServers: self.iceServers, forceRelayCandidate: self.forceRelayCandidate, useTrickleIce: self.useTrickleIce, isAnswering: false)
        self.startStatsReporter()
        self.peer?.delegate = self
        self.peer?.socket = self.socket
        self.peer?.sessionId = self.sessionId
        // Set callId for trickle ICE messages - must match the callID sent in INVITE
        self.peer?.callId = self.callInfo?.callId.uuidString.lowercased()
        Logger.log.i(message: "[TRICKLE-ICE] Call:: Peer callId set to \(self.callInfo?.callId.uuidString.lowercased() ?? "nil") for trickle ICE")
        self.peer?.offer(preferredCodecs: preferredCodecs, completion: { (sdp, error)  in

            if let error = error {
                Logger.log.i(message: "Call:: Error creating the offer: \(error)")
                return
            }

            guard let sdp = sdp else {
                return
            }
            Logger.log.i(message: "Call:: Offer completed >> SDP: \(sdp)")
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

    private func endCall(terminationReason: CallTerminationReason? = nil) {
        self.stopRingtone()
        self.stopRingbackTone()
        self.statsReporter?.dispose()
        self.peer?.dispose()
        self.updateCallState(callState: .DONE(reason: terminationReason))
    }
    
    internal func endForAttachCall() {
        self.statsReporter?.dispose()
        self.peer?.dispose()
    }

    internal func updateCallState(callState: CallState) {
        Logger.log.i(message: "Call state updated: \(callState)")
        self.callState = callState
        
        // Notify the stats reporter about the call state change
        if let statsReporter = self.statsReporter, (debug || enableQualityMetrics) {
            statsReporter.handleCallStateChange(callState: callState)
        }
        
        // Setup or remove ICE connection state monitoring based on call state
        switch callState {
        case .ACTIVE:
            setupIceConnectionStateMonitoring()
            setupRttMonitoring()
        case .DONE, .DROPPED, .HELD:
            removeIceConnectionStateMonitoring()
            removeRttMonitoring()
        default:
            break
        }
        
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
                          customHeaders:[String:String] = [:],
                          preferredCodecs: [TxCodecCapability]? = nil,
                          debug: Bool = false) {
        if (destinationNumber.isEmpty) {
            Logger.log.e(message: "Call:: Please enter a destination number.")
            return
        }
        invite(callerName: callerName,
               callerNumber: callerNumber,
               destinationNumber: destinationNumber,
               clientState: clientState,
               customHeaders: customHeaders,
               preferredCodecs: preferredCodecs,
               debug: debug)
    }

    /// Hangup or reject an incoming call.
    /// ### Example:
    ///     call.hangup()
    public func hangup() {
        Logger.log.i(message: "Call:: hangup()")
        guard let sessionId = self.sessionId, let callId = self.callInfo?.callId else { return }
        
        // Create a termination reason for local hangup
        // Use USER_BUSY
        let causeCode: CauseCode

        switch callState {
        case .ACTIVE:
            causeCode = .NORMAL_CLEARING
        case .RINGING, .CONNECTING:
            causeCode = .USER_BUSY
        default:
            causeCode = .NORMAL_CLEARING
        }

        let terminationReason = CallTerminationReason(
            cause: ByeMessage.getCauseFromCode(causeCode: causeCode),
            causeCode: causeCode.rawValue
        )

        let byeMessage = ByeMessage(sessionId: sessionId, callId: callId.uuidString, causeCode: .USER_BUSY)
        let message = byeMessage.encode() ?? ""
        self.socket?.sendMessage(message: message)
        self.endCall(terminationReason: terminationReason)
    }

    /// Starts the process to answer the incoming call.
    ///
    /// Use this method to accept an incoming call and establish the WebRTC connection.
    ///
    /// ### Examples:
    /// ```swift
    /// // Basic answer
    /// call.answer()
    ///
    /// // Answer with custom headers
    /// call.answer(customHeaders: ["X-Custom-Header": "Value"])
    ///
    /// // Answer with debug mode
    /// call.answer(debug: true)
    /// ```
    ///
    /// - Parameters:
    ///   - customHeaders: (optional) Custom Headers to be passed over webRTC Messages.
    ///     Headers should be in the format `X-key:Value` where `X-` prefix is required for custom headers.
    ///     When calling AI Agents, headers with the `X-` prefix will be mapped to dynamic variables
    ///     (e.g., `X-Account-Number` becomes `{{account_number}}`). Hyphens in header names are
    ///     converted to underscores in variable names.
    ///   - debug: (optional) Enable debug mode for call quality metrics and WebRTC statistics.
    ///     When enabled, real-time call quality metrics will be available through the `onCallQualityChange` callback.
    public func answer(customHeaders:[String:String] = [:], debug:Bool = false) {
        self.stopRingtone()
        self.stopRingbackTone()
        //TODO: Create an error if there's no remote SDP
        guard let remoteSdp = self.remoteSdp else {
            return
        }
        self.answerCustomHeaders = customHeaders
        self.configureStatsReporter()
        Logger.log.i(message: "[TRICKLE-ICE] Call:: Creating Peer for inbound call answer with useTrickleIce = \(self.useTrickleIce)")
        self.peer = Peer(iceServers: self.iceServers, forceRelayCandidate: self.forceRelayCandidate, useTrickleIce: self.useTrickleIce, isAnswering: true)
        self.enableQualityMetrics = debug
        self.startStatsReporter()
        self.peer?.delegate = self
        self.peer?.socket = self.socket
        self.peer?.sessionId = self.sessionId
        // Set callId for trickle ICE messages - must match the callID from the incoming INVITE
        self.peer?.callId = self.callInfo?.callId.uuidString.lowercased()
        Logger.log.i(message: "[TRICKLE-ICE] Call:: Peer callId set to \(self.callInfo?.callId.uuidString.lowercased() ?? "nil") for trickle ICE")
        self.incomingOffer(sdp: remoteSdp)
        self.peer?.answer(callLegId: self.telnyxLegId?.uuidString ?? "", completion: { (sdp, error)  in

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
    internal func acceptReAttach(peer: Peer?, customHeaders:[String:String] = [:],debug:Bool = false) {
        //TODO: Create an error if there's no remote SDP
        guard let remoteSdp = self.remoteSdp else {
            return
        }
        peer?.dispose()
        let reportId = self.statsReporter?.reportId
        self.enableQualityMetrics = debug
        self.statsReporter?.dispose()
        self.answerCustomHeaders = customHeaders
        self.configureStatsReporter(reportID: reportId)
        self.peer = Peer(iceServers: self.iceServers,
                         isAttach: true,
                         forceRelayCandidate: self.forceRelayCandidate,
                         useTrickleIce: false,
                         isAnswering: false)
        self.startStatsReporter()
        self.peer?.delegate = self
        self.peer?.socket = self.socket
        self.peer?.sessionId = self.sessionId
        // Set callId for trickle ICE messages - must match the callID from ATTACH
        self.peer?.callId = self.callInfo?.callId.uuidString.lowercased()
        Logger.log.i(message: "[TRICKLE-ICE] Call:: Peer callId set to \(self.callInfo?.callId.uuidString.lowercased() ?? "nil") for ATTACH")
        self.incomingOffer(sdp: remoteSdp)
        self.peer?.answer(callLegId: self.telnyxLegId?.uuidString ?? "", completion: { (sdp, error)  in

            if let error = error {
                Logger.log.e(message: "Call:: Error creating the answering: \(error)")
                return
            }

            guard let sdp = sdp else {
                return
            }
            Logger.log.i(message: "Call:: Attach completed >> SDP: \(sdp)")
        })
    }
    
    private func configureStatsReporter(reportID: UUID? = nil) {
        if (debug || enableQualityMetrics),
           let socket = self.socket {
            self.statsReporter?.dispose()
            self.statsReporter = WebRTCStatsReporter(socket: socket,reportId: reportID)
        }
    }

    private func startStatsReporter() {
        if (debug || enableQualityMetrics),
           let callId = self.callInfo?.callId {
            self.statsReporter?.startDebugReport(peerId: callId, call: self)
            
            // Only set callback if RTT monitoring is not active
            // RTT monitoring will handle the callback setup
            if !isRttMonitoringActive {
                self.statsReporter?.onStatsFrame = { metric in
                    self.onCallQualityChange?(metric)
                }
            }
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

        let dtmfMessage = InfoMessage(sessionId: sessionId,
                                      dtmf: dtmf,
                                      callInfo: callInfo,
                                      callOptions: callOptions)
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
    
    /// Resets the audio device and clears accumulated buffers to resolve persistent audio delay issues.
    ///
    /// This method addresses iOS audio delay problems where:
    /// - AudioDeviceModule buffers stretch under poor network conditions
    /// - WebRTC audio pacing causes frame accumulation
    /// - iOS AudioUnit/AVAudioSession remains in large buffer state
    ///
    /// ### Example:
    ///     call.resetAudioDevice()
    public func resetAudioDevice() {
        Logger.log.i(message: "[ACM_RESET] Call:: resetAudioDevice() - Manually resetting audio device to clear delay")
        self.peer?.resetAudioDeviceModule()
    }
    
    /// Resets the audio device module with preserved speaker state from network change
    /// This method uses the speaker state saved at the time of network change to prevent
    /// iOS from incorrectly changing the audio route during network switching
    internal func resetAudioDeviceWithNetworkState() {
        Logger.log.i(message: "[ACM_RESET] Call:: resetAudioDeviceWithNetworkState() - Using saved speaker state from network change")
        if let savedSpeakerState = speakerStateAtNetworkChange {
            Logger.log.i(message: "[ACM_RESET] Call:: Using saved speaker state: \(savedSpeakerState)")
            self.peer?.resetAudioDeviceModule(preserveSpeakerState: true, forceSpeakerState: savedSpeakerState)
            // Clear the saved state after use
            speakerStateAtNetworkChange = nil
        } else {
            Logger.log.i(message: "[ACM_RESET] Call:: No saved speaker state, using current detection")
            self.peer?.resetAudioDeviceModule()
        }
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
        } else if (self.callState == .HELD) {
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
                                              customHeaders: self.inviteCustomHeaders ?? [:],
                                              trickle: self.useTrickleIce)
            
            let message = inviteMessage.encode() ?? ""
            self.socket?.sendMessage(message: message)
            self.updateCallState(callState: .CONNECTING)
            Logger.log.s(message: "Send invite >> \(message)")
            self.playRingbackTone()
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
                                              customHeaders: self.answerCustomHeaders ?? [:],
                                              trickle: self.useTrickleIce
            )
            let message = answerMessage.encode() ?? ""
            self.socket?.sendMessage(message: message)
            Logger.log.s(message:"Send answer >> \(answerMessage)")

            // Flush queued ICE candidates after sending ANSWER (for trickle ICE on answering side)
            self.peer?.flushQueuedCandidatesAfterAnswer()
        }
    }
}

// MARK: - Hanlde Verto Messages
/**
 Handle verto messages
 */
extension Call {

    internal func handleVertoMessage(message: Message,dataMessage: String,txClient:TxClient) {

        // Handle ICE restart response (updateMedia action) - this comes as result, not method
        if let result = message.result,
           let action = result["action"] as? String,
           action == "updateMedia" {
            self.handleIceRestartResponse(message: message, dataMessage: dataMessage, txClient: txClient)
            // ICE restart response already handles speaker preservation through ACM reset mechanism
            // No need for additional speaker restoration logic at the end of this method
            return
        }

        switch message.method {
        case .BYE:
            // Extract termination reason details from the message if available
            var terminationReason: CallTerminationReason? = nil
            
            if let params = message.params {
                let cause = params["cause"] as? String
                let causeCode = params["causeCode"] as? Int
                let sipCode = params["sipCode"] as? Int
                let sipReason = params["sipReason"] as? String
                
                // Only create a termination reason if we have at least one field
                if cause != nil || causeCode != nil || sipCode != nil || sipReason != nil {
                    terminationReason = CallTerminationReason(
                        cause: cause,
                        causeCode: causeCode,
                        sipCode: sipCode,
                        sipReason: sipReason
                    )
                }
            }
            
            // Close call with termination reason
            self.endCall(terminationReason: terminationReason)
            
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

                    // Update peer's callLegID and flush any pending trickle ICE candidates
                    self.peer?.callLegID = telnyxLegIdUUID.uuidString
                    Logger.log.i(message: "[TRICKLE-ICE] Call:: Updated peer.callLegID with telnyxLegId, flushing pending candidates")
                    self.peer?.flushPendingTrickleCandidates()
                } else {
                    Logger.log.w(message: "Call:: Telnyx Leg ID unavailable on RINGING message")
                }
            }
            self.updateCallState(callState: .RINGING)
            break
            
        case .MODIFY:
            // Handle other MODIFY actions (hold/unhold, etc.)
            // ICE restart is handled at the beginning of the method
            break

        case .CANDIDATE:
            // Handle incoming remote ICE candidate for trickle ICE
            if let params = message.params {
                guard let candidateString = params["candidate"] as? String else {
                    Logger.log.w(message: "[TRICKLE-ICE] Call:: CANDIDATE message missing candidate string")
                    return
                }

                let sdpMid = params["sdpMid"] as? String
                let sdpMLineIndex = params["sdpMLineIndex"] as? Int32 ?? 0

                Logger.log.i(message: "[TRICKLE-ICE] Call:: Received remote candidate - forwarding to peer")
                self.peer?.handleRemoteCandidate(candidateString: candidateString, sdpMid: sdpMid, sdpMLineIndex: sdpMLineIndex)
            }
            break

        case .END_OF_CANDIDATES:
            // Handle end of remote candidates signal for trickle ICE
            Logger.log.i(message: "[TRICKLE-ICE] Call:: Received END_OF_CANDIDATES - forwarding to peer")
            self.peer?.handleEndOfRemoteCandidates()
            break

        default:
            Logger.log.w(message: "TxClient:: SocketDelegate Default method")
            break
        }

        // Restore speaker state after audio session is fully configured
        // Use verification and retry logic to ensure speaker is actually restored
        if txClient.isSpeakerEnabled {
            Logger.log.w(message: "Speaker Enabled - will restore after audio session configuration")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak txClient] in
                guard let txClient = txClient else { return }
                Logger.log.i(message: "[ACM_RESET] Restoring speaker after attach/reconnect with verification")
                txClient.restoreSpeakerAfterReconnect()
            }
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

// MARK: - ICE Connection State Monitoring
extension Call {
    
    /// Sets up automatic ICE connection state monitoring for the active call
    private func setupIceConnectionStateMonitoring() {
        Logger.log.i(message: "Call:: Setting up ICE connection state monitoring")
        
        // Set up callback to monitor ICE connection state changes
        self.peer?.onIceConnectionStateChange = { [weak self] newState in
            self?.handleIceConnectionStateTransition(from: self?.previousIceConnectionState ?? .new, to: newState)
            self?.previousIceConnectionState = newState
        }
    }
    
    /// Removes automatic ICE connection state monitoring
    private func removeIceConnectionStateMonitoring() {
        Logger.log.i(message: "Call:: Removing ICE connection state monitoring")
        
        // Clear the callback
        self.peer?.onIceConnectionStateChange = nil
    }
    
    /// Handles ICE connection state transitions for automatic recovery
    /// - Parameters:
    ///   - from: Previous ICE connection state
    ///   - to: New ICE connection state
    private func handleIceConnectionStateTransition(from previousState: RTCIceConnectionState, to newState: RTCIceConnectionState) {
        Logger.log.i(message: "Call:: ICE state transition: \(previousState.telnyx_to_string()) -> \(newState.telnyx_to_string())")
        
        // Case 1: disconnected -> failed: Attempt ICE restart/renegotiation
        if previousState == .disconnected && newState == .failed {
            Logger.log.w(message: "Call:: ICE connection failed after disconnect - attempting ICE restart")
            
            // Save current speaker state immediately before iOS can change audio route due to network change
            let currentRoute = AVAudioSession.sharedInstance().currentRoute
            speakerStateAtNetworkChange = currentRoute.outputs.contains { $0.portType == .builtInSpeaker }
            Logger.log.i(message: "Call:: Saved speaker state at network change: \(speakerStateAtNetworkChange ?? false)")
            
            // Trigger ICE restart to recover from failed state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.performIceRestart { success, error in
                    if success {
                        Logger.log.i(message: "Call:: Auto ICE restart completed successfully")
                    } else {
                        Logger.log.e(message: "Call:: Auto ICE restart failed: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        }
        
        // Track first successful connection
        if newState == .connected && !hasBeenConnectedBefore {
            hasBeenConnectedBefore = true
            Logger.log.i(message: "[ACM_RESET] Call:: First ICE connection established - ACM reset disabled for initial connection")
        }

        // Case 2: connected -> disconnected: Reset audio buffers (only on reconnection)
        if previousState == .connected && newState == .disconnected && hasBeenConnectedBefore {
            Logger.log.w(message: "[ACM_RESET] Call:: ICE connection disconnected during active call - resetting audio buffers")
            
            // Save current speaker state immediately before iOS can change audio route due to network change
            let currentRoute = AVAudioSession.sharedInstance().currentRoute
            speakerStateAtNetworkChange = currentRoute.outputs.contains { $0.portType == .builtInSpeaker }
            Logger.log.i(message: "Call:: Saved speaker state at network disconnect: \(speakerStateAtNetworkChange ?? false)")

            // Reset audio device module to clear accumulated buffers
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                Logger.log.i(message: "[ACM_RESET] Call:: Triggering resetAudioDeviceModule from ICE disconnect")
                self?.resetAudioDeviceWithNetworkState()
            }
        }

        // Case 3: disconnected -> connected: Reset audio buffers (only on reconnection)
        if previousState == .disconnected && newState == .connected && hasBeenConnectedBefore {
            Logger.log.i(message: "[ACM_RESET] Call:: ICE connection restored after disconnect - resetting audio buffers")

            // Reset audio device module to clear accumulated buffers
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                Logger.log.i(message: "[ACM_RESET] Call:: Triggering resetAudioDeviceModule from ICE reconnection")
                self?.resetAudioDeviceWithNetworkState()
            }
        }
    }
    
    /// Performs ICE restart using the existing Call+IceRestart implementation
    /// - Parameter completion: Callback with success status and error
    private func performIceRestart(completion: @escaping (Bool, Error?) -> Void) {
        guard let _ = self.peer else {
            Logger.log.e(message: "Call:: performIceRestart - No peer connection available")
            completion(false, NSError(domain: "Call", code: -1, userInfo: [NSLocalizedDescriptionKey: "No peer connection available"]))
            return
        }
        
        Logger.log.i(message: "Call:: Starting ICE restart")
        
        // Set ICE restart flags
        self.isIceRestarting = true
        self.shouldResetAudioAfterIceRestart = true
        
        // Use the existing iceRestart method from Call+IceRestart
        self.iceRestart { [weak self] success, error in
            guard let self = self else { return }
            
            if success {
                Logger.log.i(message: "Call:: ICE restart completed successfully")
                completion(true, nil)
            } else {
                Logger.log.e(message: "Call:: ICE restart failed: \(error?.localizedDescription ?? "Unknown error")")
                self.isIceRestarting = false
                self.shouldResetAudioAfterIceRestart = false
                completion(false, error)
            }
        }
    }
}

// MARK: - RTT Monitoring
extension Call {
    
    /// Sets up RTT monitoring for automatic audio reset when RTT is high
    private func setupRttMonitoring() {
        Logger.log.i(message: "[RTT] Call:: Setting up RTT monitoring - Call state: \(callState)")

        isRttMonitoringActive = true
        lastAudioResetTime = Date.distantPast
        currentRttMs = 0.0
        
        // Set up callback to monitor RTT metrics from WebRTCStatsReporter
        self.statsReporter?.onStatsFrame = { [weak self] metrics in
            // Forward to user callback if set
            self?.onCallQualityChange?(metrics)
            // Handle RTT monitoring
            self?.handleRttMetrics(metrics: metrics)
        }
    }
    
    /// Removes RTT monitoring
    private func removeRttMonitoring() {
        Logger.log.i(message: "[RTT] Call:: Removing RTT monitoring")
        
        isRttMonitoringActive = false
        stopRttResetTimer()
        currentRttMs = 0.0
        
        // Restore original callback behavior (only forward to user callback)
        self.statsReporter?.onStatsFrame = { [weak self] metrics in
            self?.onCallQualityChange?(metrics)
        }
    }
    
    /// Handles RTT metrics and triggers audio reset when needed
    /// - Parameter metrics: Call quality metrics containing RTT information
    private func handleRttMetrics(metrics: CallQualityMetrics) {
        guard isRttMonitoringActive else { return }

        // Validate RTT value - ignore if invalid (inf, nan, or negative)
        guard metrics.rtt.isFinite && metrics.rtt >= 0 else {
            Logger.log.i(message: "[RTT] Call:: Ignoring invalid RTT value: \(metrics.rtt)")
            return
        }

        currentRttMs = metrics.rtt * 1000 // Convert to milliseconds and store

        Logger.log.i(message: "[RTT] Call:: Current RTT: \(String(format: "%.1f", currentRttMs))ms")

        // Case 1: RTT >= 500ms - Start timer if not already running
        if currentRttMs >= 500 {
            if rttResetTimer == nil {
                Logger.log.w(message: "[RTT] Call:: HIGH RTT detected: \(String(format: "%.1f", currentRttMs))ms - Starting timer")
                startRttResetTimer()
            }
        }
        // Case 2: RTT < 500ms - Stop timer
        else {
            if rttResetTimer != nil {
                Logger.log.i(message: "[RTT] Call:: RTT normalized: \(String(format: "%.1f", currentRttMs))ms - Stopping timer")
                stopRttResetTimer()
            }
        }
    }
    
    /// Starts a timer to reset audio in 5 seconds if RTT is still high
    private func startRttResetTimer() {
        Logger.log.i(message: "[RTT] Call:: Starting 5-second reset timer")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.rttResetTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                guard let self = self, self.isRttMonitoringActive else {
                    return
                }

                Logger.log.i(message: "[RTT] Timer fired - Current RTT: \(String(format: "%.1f", self.currentRttMs))ms")

                // Clear timer first
                self.rttResetTimer = nil

                // Only reset if RTT is still >= 1000ms
                if self.currentRttMs >= 1000 {
                    Logger.log.w(message: "[RTT] AUDIO RESET triggered - RTT: \(String(format: "%.1f", self.currentRttMs))ms")
                    self.resetAudioForHighRtt()

                    // Start new timer for next reset (will be handled by next RTT metric)
                    Logger.log.i(message: "[RTT] Timer completed, next timer will start on next high RTT metric")
                } else {
                    Logger.log.i(message: "[RTT] RTT normalized, timer stopped")
                }
            }
        }
    }

    /// Stops the RTT reset timer
    private func stopRttResetTimer() {
        rttResetTimer?.invalidate()
        rttResetTimer = nil
    }
    
    /// Resets audio device module due to high RTT
    private func resetAudioForHighRtt() {
        Logger.log.w(message: "[RTT] EXECUTING AUDIO RESET")

        // Reset audio device module
        self.peer?.resetAudioDeviceModule()

        // Update last reset time for tracking purposes
        lastAudioResetTime = Date()
    }
}

