//
//  Peer.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 03/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation
import WebRTC
import AVFoundation

protocol PeerDelegate: AnyObject {
    func onNegotiationEnded(sdp: RTCSessionDescription?)
}

/// The Peer class manages WebRTC peer connections, handling audio/video streams and ICE negotiation.
/// It provides functionality for:
/// - Setting up and managing WebRTC peer connections
/// - Handling audio and video tracks
/// - Managing ICE candidates and negotiation
/// - Controlling media state (mute/unmute)
/// - Monitoring connection state changes
class Peer : NSObject, WebRTCEventHandler {

    /// Queue for handling audio operations to ensure thread safety
    private let audioQueue = DispatchQueue(label: "audio")
    
    /// Timeout duration for ICE negotiation in seconds (traditional mode)
    private let NEGOTIATION_TIMOUT = 0.3

    /// Timeout duration for Trickle ICE end of candidates detection in seconds
    /// Longer timeout to ensure all candidates (including TURN relay) are gathered
    private let TRICKLE_ICE_TIMEOUT = 3.0

    /// Identifier for the audio track in WebRTC connection
    private let AUDIO_TRACK_ID = "audio0"
    
    /// Identifier for the video track in WebRTC connection
    private let VIDEO_TRACK_ID = "video0"
    
    /// Local video file used for testing in simulator environment
    private let VIDEO_DEMO_LOCAL_VIDEO = "local_video_streaming.mp4"
    
    /// Collection of gathered ICE candidates during connection setup
    internal var gatheredICECandidates: [String] = []

    /// Note: Queue system removed - candidates are now sent immediately using callId
    /// from the INVITE message instead of waiting for callLegID from backend

    /// Socket connection for signaling with the WebRTC server
    var socket: Socket?

    /// The session ID for this WebRTC session
    var sessionId: String?

    /// Controls whether trickle ICE is enabled for this peer connection
    var useTrickleIce: Bool = false

    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                                   kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueFalse]

    /// Removes ICE candidate lines from SDP for Trickle ICE mode
    /// - Parameter sdp: The original SDP with candidates
    /// - Returns: SDP without candidate lines
    private func removeCandidatesFromSDP(_ sdp: String) -> String {
        let lines = sdp.components(separatedBy: "\r\n")
        let filteredLines = lines.filter { line in
            // Keep all lines except candidate lines
            !line.hasPrefix("a=candidate:")
        }
        let cleanedSDP = filteredLines.joined(separator: "\r\n")

        let candidatesRemoved = lines.count - filteredLines.count
        Logger.log.i(message: "[TRICKLE-ICE] Peer:: Removed \(candidatesRemoved) candidate lines from SDP")

        return cleanedSDP
    }

    weak var delegate: PeerDelegate?
    var connection : RTCPeerConnection?

    /// Configured ICE servers for this peer connection
    /// Used to validate gathered ICE candidates against configured servers
    private var configuredIceServers: [RTCIceServer]

    //Audio
    private var localAudioTrack: RTCAudioTrack?
    private let rtcAudioSession =  RTCAudioSession.sharedInstance()

    //Video
    private var videoCapturer: RTCVideoCapturer?
    private var localVideoTrack: RTCVideoTrack?
    private var remoteVideoTrack: RTCVideoTrack?

    /// The call ID used in the INVITE message (callInfo.callId from Call)
    /// This should be used for trickle ICE messages to match the INVITE
    internal var callId: String?

    /// The call leg ID received from backend (telnyxLegId from Call)
    /// Only used for backward compatibility - new code should use callId
    internal var callLegID: String?

    //Data channel
    private var localDataChannel: RTCDataChannel?
    private var remoteDataChannel: RTCDataChannel?
    
    //Media streams
    private var _localStream: RTCMediaStream?
    private var _remoteStream: RTCMediaStream?

    //ICE negotiation
    private var negotiationTimer: Timer?
    internal var negotiationEnded: Bool = false
    internal var isIceRestarting: Bool = false
    internal var iceRestartCompletion: ((_ sdp: RTCSessionDescription?, _ error: Error?) -> Void)?

    /// Flag to track if endOfCandidates message has been sent for the current session
    /// Prevents sending duplicate endOfCandidates messages during trickle ICE
    private var endOfCandidatesSent: Bool = false

    /// Queued candidates for answering side (until ANSWER is sent)
    /// When answering a call, we queue local ICE candidates until the ANSWER is sent
    /// to avoid race conditions where candidates arrive before the ANSWER
    private var queuedCandidates: [RTCIceCandidate] = []

    /// Flag to track if the ANSWER has been sent (for answering side)
    private var answerSent: Bool = false

    /// Flag to indicate if this peer is on the answering side of a call
    private var isAnswering: Bool = false

    // WEBRTC STATS
    var onSignalingStateChange: ((RTCSignalingState, RTCPeerConnection) -> Void)?
    var onAddStream: ((RTCMediaStream) -> Void)?
    var onRemoveStream: ((RTCMediaStream) -> Void)?
    var onNegotiationNeeded: (() -> Void)?
    var onIceConnectionChange: ((RTCIceConnectionState) -> Void)?
    var onIceGatheringChange: ((RTCIceGatheringState) -> Void)?
    
    /// Callback for ICE connection state monitoring (independent of WebRTC stats)
    /// This is used for automatic recovery and audio buffer management
    var onIceConnectionStateChange: ((RTCIceConnectionState) -> Void)?

    // Call-report logging closures (separate from WebRTCStatsReporter callbacks)
    var onSignalingStateChangeForLog: ((RTCSignalingState) -> Void)?
    var onIceGatheringStateChangeForLog: ((RTCIceGatheringState) -> Void)?
    var onIceCandidate: ((RTCIceCandidate) -> Void)?
    var onRemoveIceCandidates: (([RTCIceCandidate]) -> Void)?
    var onDataChannel: ((RTCDataChannel) -> Void)?

    public var isAudioTrackEnabled: Bool {
        if self.connection?.configuration.sdpSemantics == .planB {
            return self.connection?.senders
                .compactMap { $0.track as? RTCAudioTrack }
                .first?.isEnabled ?? false
        } else {
            return self.connection?.transceivers
                .compactMap { $0.sender.track as? RTCAudioTrack }
                .first?.isEnabled ?? false
        }
    }
    
    /// The local media stream containing audio and/or video tracks being sent to the remote peer.
    /// This stream is created when the peer connection is established and contains the local media tracks.
    public var localStream: RTCMediaStream? {
        return _localStream
    }
    
    /// The remote media stream containing audio and/or video tracks received from the remote peer.
    /// This stream is populated when the remote peer adds media tracks to the connection.
    public var remoteStream: RTCMediaStream? {
        return _remoteStream
    }
    
    // The `RTCPeerConnectionFactory` is in charge of creating new RTCPeerConnection instances.
    // A new RTCPeerConnection should be created every new call, but the factory is shared.
    internal static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()


    @available(*, unavailable)
    override init() {
        fatalError("Peer:init is unavailable")
    }

    required init(iceServers: [RTCIceServer],
                  isAttach: Bool = false,
                  forceRelayCandidate: Bool = false,
                  useTrickleIce: Bool = false,
                  isAnswering: Bool = false) {
        self.configuredIceServers = iceServers
        self.isAnswering = isAnswering

        let config = RTCConfiguration()
        config.iceServers = iceServers

        // Unified plan is more superior than planB
        config.sdpSemantics = .unifiedPlan
        config.bundlePolicy = .maxCompat

        // Control local network access for ICE candidate gathering
        if forceRelayCandidate {
            config.iceTransportPolicy = .relay // Force TURN relay to avoid local network access
        }

        // gatherContinually will let WebRTC to listen to any network changes and send any new candidates to the other client
        config.continualGatheringPolicy = .gatherContinually

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil,
                                              optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue])
        self.connection = Peer.factory.peerConnection(with: config, constraints: constraints, delegate: nil)

        super.init()
        self.useTrickleIce = useTrickleIce
        Logger.log.i(message: "[TRICKLE-ICE] Peer:: Initialized with useTrickleIce = \(useTrickleIce), isAnswering = \(isAnswering)")
        self.createMediaSenders()
        if (!isAttach) {
            self.configureAudioSession()
        }
        //listen RTCPeer connection events
        self.connection?.delegate = self
    }

    private func createMediaSenders() {
        let streamId = UUID.init().uuidString.lowercased()

        // Create local media stream
        self._localStream = Peer.factory.mediaStream(withStreamId: streamId)

        // let's support Audio first.
        let audioTrack = self.createAudioTrack()
        self.localAudioTrack = audioTrack
        self._localStream?.addAudioTrack(audioTrack)
        self.connection?.add(audioTrack, streamIds: [streamId])
        self.muteUnmuteAudio(mute: false)
    }

    /// Configures the iOS device's audio session for optimal WebRTC call handling.
    /// This setup is crucial for proper audio routing and behavior during calls.
    ///
    /// The configuration includes:
    /// - Setting up manual audio control for precise handling
    /// - Configuring the audio session for VoIP calls
    /// - Enabling Bluetooth device support
    /// - Setting up audio mixing behavior with other apps
    ///
    /// Audio session options:
    /// - `.allowBluetoothA2DP`: Enables high-quality Bluetooth audio
    /// - `.duckOthers`: Reduces other apps' audio volume during calls
    /// - `.allowBluetooth`: Enables classic Bluetooth headset support
    /// - `.mixWithOthers`: Allows mixing with audio from other apps
    ///
    /// This method runs asynchronously on a dedicated audio queue to prevent blocking.
    internal func configureAudioSession() {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.rtcAudioSession.lockForConfiguration()
            do {
                Logger.log.i(message: "Peer:: Configuring AVAudioSession")
                self.rtcAudioSession.useManualAudio = true
                self.rtcAudioSession.isAudioEnabled = false
                try rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord,
                                                mode: AVAudioSession.Mode.voiceChat,
                                                options: [
                                                    .duckOthers,          // Reduce other apps' volume
                                                    .allowBluetooth,      // Enable Bluetooth headsets
                                                ])

                try rtcAudioSession.setPreferredIOBufferDuration(0.01) // 10 ms

                Logger.log.i(message: "Peer:: AVAudioSession configured successfully")
            } catch let error {
                Logger.log.e(message: "Peer:: Error changing AVAudioSession category: \(error.localizedDescription)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }

    private func createAudioTrack() -> RTCAudioTrack {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = Peer.factory.audioSource(with: audioConstrains)
        //TODO: trackId should be auto generated.
        let audioTrack = Peer.factory.audioTrack(with: audioSource, trackId: AUDIO_TRACK_ID)
        return audioTrack
    }

    private func createVideoTrack() -> RTCVideoTrack {
        let videoSource = Peer.factory.videoSource()
        
        #if targetEnvironment(simulator)
            //if we are using the simulator:
            //we will access a local video to stream if there's a video call
            //check: self.startCaptureLocalVideo
            self.videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
        #else
            self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        #endif
        //TODO: trackId should be auto generated.
        let videoTrack = Peer.factory.videoTrack(with: videoSource, trackId: VIDEO_TRACK_ID)
        return videoTrack
    }

    /// Applies audio codec preferences to the peer connection's audio transceiver.
    ///
    /// This internal method configures the WebRTC audio transceiver to use the specified codecs
    /// in priority order. It should be called before creating an offer or answer to ensure the
    /// codec preferences are included in the SDP negotiation.
    ///
    /// The method:
    /// 1. Retrieves all supported audio codecs from the WebRTC framework
    /// 2. Matches user preferences against supported codecs
    /// 3. Applies the ordered codec list to the audio transceiver
    ///
    /// If no matching codecs are found, a warning is logged and no preferences are applied,
    /// allowing WebRTC to use its default codec selection.
    ///
    /// - Parameter preferredCodecs: Array of TxCodecCapability objects representing the preferred codec order.
    ///   Each codec must match a supported codec by mimeType, clockRate, and optionally channels.
    func applyAudioCodecPreferences(preferredCodecs: [TxCodecCapability]) {
        guard let connection = self.connection else {
            Logger.log.w(message: "Peer:: applyAudioCodecPreferences() - No peer connection available")
            return
        }

        // Find the audio transceiver
        guard let audioTransceiver = connection.transceivers.first(where: { $0.mediaType == .audio }) else {
            Logger.log.w(message: "Peer:: applyAudioCodecPreferences() - No audio transceiver found")
            return
        }

        // Get all supported audio codec capabilities from the factory
        let capabilities = Peer.factory.rtpSenderCapabilities(forKind: kRTCMediaStreamTrackKindAudio)
        let allCodecs = capabilities.codecs

        // Match and order the codecs according to user preferences
        var orderedCodecs: [RTCRtpCodecCapability] = []

        for preferredCodec in preferredCodecs {
            // Find matching RTCRtpCodecCapability from supported codecs
            if let matchingCodec = allCodecs.first(where: { preferredCodec.matches($0) }) {
                orderedCodecs.append(matchingCodec)
            }
        }

        guard !orderedCodecs.isEmpty else {
            Logger.log.w(message: "Peer:: applyAudioCodecPreferences() - No matching codecs found")
            return
        }

        // Apply the ordered codec preferences
        audioTransceiver.setCodecPreferences(orderedCodecs)
        Logger.log.i(message: "Peer:: Applied codec preferences to audio transceiver: \(preferredCodecs.map { $0.mimeType }.joined(separator: ", "))")
    }

    // MARK: Signaling OFFER
    /// Creates a WebRTC offer for initiating an outbound call.
    ///
    /// For Trickle ICE mode:
    /// - Sends the SDP immediately without waiting for ICE candidates
    /// - Candidates are sent separately as they are generated
    ///
    /// For traditional mode:
    /// - Waits for ICE candidates to be gathered
    /// - Sends SDP with candidates included
    ///
    /// - Parameters:
    ///   - preferredCodecs: (optional) Array of preferred audio codecs in priority order.
    ///     If provided, these codecs will be applied to the audio transceiver before creating the offer,
    ///     ensuring they appear in the correct priority order in the SDP.
    ///   - completion: Callback invoked when the offer is created.
    ///     - sdp: The generated session description, or nil if an error occurred
    ///     - error: An error if the offer creation failed, or nil on success
    func offer(preferredCodecs: [TxCodecCapability]? = nil, completion: @escaping (_ sdp: RTCSessionDescription?, _ error: Error?) -> Void) {

        // Apply codec preferences before creating offer
        if let codecs = preferredCodecs, !codecs.isEmpty {
            self.applyAudioCodecPreferences(preferredCodecs: codecs)
        }

        let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains,
                                             optionalConstraints: nil)
        self.negotiationEnded = false
        self.endOfCandidatesSent = false
        self.connection?.offer(for: constrains) { (sdp, error) in

            if let error = error {
                Logger.log.e(message: "Peer:: error creating offer \(error)")
                completion(sdp, error)
                return
            }

            guard let sdp = sdp else {
                Logger.log.w(message: "Peer:: SDP is missing")
                return
            }

            //Once we set the local description, the ICE negotiation starts and at least one ICE candidate should be created.
            //Check RTCPeerConnectionDelegate :: didGenerate candidate
            self.connection?.setLocalDescription(sdp, completionHandler: { (error) in
                // For Trickle ICE, send the SDP immediately via delegate without waiting for candidates
                if self.useTrickleIce {
                    Logger.log.i(message: "[TRICKLE-ICE] Peer:: offer() completed - sending SDP immediately without candidates (Trickle ICE mode)")
                    // DO NOT set negotiationEnded = true here for Trickle ICE
                    // We want candidates to continue being sent individually

                    // Remove candidates from SDP and add trickle ICE capability for Trickle ICE
                    if let localSDP = self.connection?.localDescription {
                        let cleanedSDPString = self.removeCandidatesFromSDP(localSDP.sdp)
                        let modifiedSDPString = SdpUtils.addTrickleIceCapability(cleanedSDPString, useTrickleIce: self.useTrickleIce)
                        let cleanedSDP = RTCSessionDescription(type: localSDP.type, sdp: modifiedSDPString)
                        self.delegate?.onNegotiationEnded(sdp: cleanedSDP)
                    } else {
                        self.delegate?.onNegotiationEnded(sdp: nil)
                    }
                } else {
                    Logger.log.i(message: "Peer:: offer() completed - will wait for ICE candidates (traditional mode)")
                }

                completion(sdp, nil)
            })
        }
    }


    // MARK: Signaling ANSWER
    /// Creates a WebRTC answer for responding to an incoming call.
    ///
    /// For Trickle ICE mode:
    /// - Sends the SDP answer immediately without waiting for ICE candidates
    /// - Candidates are sent separately as they are generated
    ///
    /// For traditional mode:
    /// - Waits for ICE candidates to be gathered
    /// - Sends SDP with candidates included
    ///
    /// - Parameters:
    ///   - callLegId: The call leg identifier for tracking this call session
    ///   - completion: Callback invoked when the answer is created.
    ///     - sdp: The generated session description, or nil if an error occurred
    ///     - error: An error if the answer creation failed, or nil on success
    func answer(callLegId: String, completion: @escaping (_ sdp: RTCSessionDescription?, _ error: Error?) -> Void) {
        self.negotiationEnded = false
        self.endOfCandidatesSent = false

        let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains,
                                             optionalConstraints: nil)
        // Store callLegID for backward compatibility, but it's no longer used for trickle ICE
        self.callLegID = callLegId
        Logger.log.i(message: "[TRICKLE-ICE] Peer:: answer() - callLegID received: \(callLegId) (note: using callId for trickle ICE)")

        self.connection?.answer(for: constrains) { (sdp, error) in

            if let error = error {
                Logger.log.e(message: "Peer:: error creating answer \(error)")
                completion(sdp, error)
                return
            }

            //TODO: we should return an error. We don't have a local SDP
            guard let sdp = sdp else {
                Logger.log.w(message: "Peer:: SDP is missing")
                return
            }

            //Once we set the local description, the ICE negotiation starts and at least one ICE candidate should be created.
            //Check RTCPeerConnectionDelegate :: didGenerate candidate
            self.connection?.setLocalDescription(sdp, completionHandler: { (error) in
                // For Trickle ICE, send the SDP immediately via delegate without waiting for candidates
                if self.useTrickleIce {
                    Logger.log.i(message: "[TRICKLE-ICE] Peer:: answer() completed - sending SDP immediately without candidates (Trickle ICE mode)")
                    // DO NOT set negotiationEnded = true here for Trickle ICE
                    // We want candidates to continue being sent individually

                    // Remove candidates from SDP and add trickle ICE capability for Trickle ICE
                    if let localSDP = self.connection?.localDescription {
                        let cleanedSDPString = self.removeCandidatesFromSDP(localSDP.sdp)
                        let modifiedSDPString = SdpUtils.addTrickleIceCapability(cleanedSDPString, useTrickleIce: self.useTrickleIce)
                        let cleanedSDP = RTCSessionDescription(type: localSDP.type, sdp: modifiedSDPString)
                        self.delegate?.onNegotiationEnded(sdp: cleanedSDP)
                    } else {
                        self.delegate?.onNegotiationEnded(sdp: nil)
                    }
                } else {
                    Logger.log.i(message: "Peer:: answer() completed - will wait for ICE candidates (traditional mode)")
                }

                completion(sdp, nil)
            })
        }
    }

    /**
     This code should be started when the first ICE candidate is created.

     For Trickle ICE:
     - Uses a timer to detect when candidates stop arriving
     - When timer expires, sends endOfCandidates message
     - Timer is restarted with each new candidate

     For non-Trickle ICE (traditional):
     - Waits for candidates to accumulate using a timer
     - Sends SDP with all candidates included after timeout
     */
    fileprivate func startNegotiation(peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        Logger.log.i(message: "[TRICKLE-ICE] Peer:: startNegotiation called (useTrickleIce: \(useTrickleIce))")

        // For Trickle ICE: restart timer to send endOfCandidates when no more candidates arrive
        // Using longer timeout (2s) to ensure all candidates including TURN relay are gathered
        if useTrickleIce {
            Logger.log.i(message: "[TRICKLE-ICE] Peer:: Restarting negotiation timer for endOfCandidates detection (timeout: \(self.TRICKLE_ICE_TIMEOUT)s)")

            // Restart the negotiation timer
            self.negotiationTimer?.invalidate()
            self.negotiationTimer = nil
            DispatchQueue.main.async {
                self.negotiationTimer = Timer.scheduledTimer(withTimeInterval: self.TRICKLE_ICE_TIMEOUT, repeats: false) { timer in
                    self.negotiationTimer?.invalidate()

                    Logger.log.i(message: "[TRICKLE-ICE] Peer:: No more candidates for \(self.TRICKLE_ICE_TIMEOUT)s - sending endOfCandidates")
                    self.sendEndOfCandidates()
                }
            }
            return
        }

        // Traditional non-trickle ICE: wait for candidates to accumulate
        Logger.log.i(message: "Peer:: ICE negotiation updated (traditional mode)")

        //Restart the negotiation timer
        self.negotiationTimer?.invalidate()
        self.negotiationTimer = nil
        DispatchQueue.main.async {
            self.negotiationTimer = Timer.scheduledTimer(withTimeInterval: self.NEGOTIATION_TIMOUT, repeats: false) { timer in
                // Check if the negotiation process has ended to avoid duplicated calls to the delegate method.
                if self.negotiationEnded {
                    Logger.log.w(message: "ICE negotiation has ended:: For Peer")
                    return
                }
                self.negotiationTimer?.invalidate()
                self.negotiationEnded = true

                // Handle ICE restart completion
                if self.isIceRestarting, let completion = self.iceRestartCompletion {
                    self.iceRestartCompletion = nil
                    self.createFinalOfferWithCandidates(completion: completion)
                } else {
                    // At this moment we should have at least one ICE candidate.
                    // Lets stop the ICE negotiation process and call the apropiate delegate
                    self.delegate?.onNegotiationEnded(sdp: peerConnection.localDescription)
                }
                Logger.log.i(message: "Peer:: ICE negotiation ended.")
            }
        }
    }

    /// Close connection and release resources
    func dispose() {
        Logger.log.i(message: "Peer:: dispose()")

        self.connection?.close()
        self.delegate = nil

        self.localAudioTrack = nil
        self.localVideoTrack = nil
        self.localDataChannel = nil

        self.remoteVideoTrack = nil
        self.remoteDataChannel = nil

        self.onSignalingStateChange = nil
        self.onAddStream = nil
        self.onRemoveStream = nil
        self.onNegotiationNeeded = nil
        self.onIceConnectionChange = nil
        self.onIceGatheringChange = nil
        self.onIceConnectionStateChange = nil
        self.onSignalingStateChangeForLog = nil
        self.onIceGatheringStateChangeForLog = nil
        self.onIceCandidate = nil
        self.onRemoveIceCandidates = nil
        self.onDataChannel = nil

        // Reset trickle ICE state
        self.endOfCandidatesSent = false
        self.negotiationTimer?.invalidate()
        self.negotiationTimer = nil

        // Clear queued candidates and reset answering flags
        self.queuedCandidates.removeAll()
        self.answerSent = false
    }


}
// MARK: - Tracks handling
extension Peer {
    //DO NOT USE THIS FOR planB
    private func setTrackEnabled<T: RTCMediaStreamTrack>(_ type: T.Type, isEnabled: Bool) {
        Logger.log.i(message: "setTrackEnabled: \(isEnabled)")

        if let transceivers = self.connection?.transceivers {
            Logger.log.i(message:"setTrackEnabled: transeivers \(transceivers)")

            transceivers.compactMap { return $0.sender.track as? T }
            .forEach {
                $0.isEnabled = isEnabled
                Logger.log.i(message:"setTrackEnabled IsEnabled: \(isEnabled)")
            }
        } else {
            Logger.log.i(message:"setTrackEnabled transeivers empty")
        }
    }
}

// MARK: - Audio handling
extension Peer {
    /// Controls the mute state of the local audio track in the WebRTC connection.
    ///
    /// This method handles audio track state changes for both legacy (Plan B) and modern (Unified Plan)
    /// WebRTC implementations. It properly manages the audio track state based on the connection's
    /// SDP semantics.
    ///
    /// - Parameter mute: Boolean flag to control audio state
    ///   - `true`: Mutes the local audio (disables the audio track)
    ///   - `false`: Unmutes the local audio (enables the audio track)
    ///
    /// Implementation details:
    /// - For Plan B semantics: Uses the connection's senders to find and modify the audio track
    /// - For Unified Plan: Uses transceivers to manage the audio track state
    /// - Includes AudioDeviceModule reset to clear accumulated audio buffers and resolve delay issues
    ///
    /// Note: This method is used internally by the Call class through its public `muteAudio()`
    /// and `unmuteAudio()` methods.
    func muteUnmuteAudio(mute: Bool) {
        Logger.log.i(message: "Peer:: muteUnmuteAudio(mute: \(mute))")
        
        // GetTransceivers is only supported with Unified Plan SdpSemantics.
        // PlanB doesn't have support to access transeivers, so we need to use the stored audio track
        if self.connection?.configuration.sdpSemantics == .planB {
            self.connection?.senders
                .compactMap { return $0.track as? RTCAudioTrack } // Search for Audio track
                .forEach {
                    $0.isEnabled = !mute // disable/enable RTCAudioTrack
                }
        } else {
            self.setTrackEnabled(RTCAudioTrack.self, isEnabled: !mute)
        }
        
        Logger.log.i(message: "[ACM_RESET] Peer:: Audio track \(mute ? "muted" : "unmuted")")
    }
    
    /// Resets the AudioDeviceModule to clear accumulated audio buffers and resolve delay issues
    /// 
    /// This method addresses the iOS audio delay problem where:
    /// - The AudioDeviceModule (ADM) buffer stretches under poor network conditions
    /// - WebRTC applies audio pacing to prevent overloading the send queue
    /// - Captured frames accumulate before being processed, causing persistent uplink delay
    /// - iOS AudioUnit/AVAudioSession buffering can remain in a state with large buffers
    /// 
    /// - Parameter preserveSpeakerState: Whether to preserve the current speakerphone state during reset
    /// - Parameter forceSpeakerState: Optional forced speaker state to use instead of detecting current state
    func resetAudioDeviceModule(preserveSpeakerState: Bool = true, forceSpeakerState: Bool? = nil) {
        guard let connection = self.connection else {
            Logger.log.w(message: "[ACM_RESET] Peer:: resetAudioDeviceModule() - No active connection")
            return
        }

        Logger.log.i(message: "[ACM_RESET] Peer:: Starting AudioDeviceModule reset via mute/unmute sequence (Unified Plan)")

        // Notify TxClient that ACM reset is starting (to ignore audio route changes)
        NotificationCenter.default.post(
            name: NSNotification.Name(InternalConfig.NotificationNames.acmResetStarted),
            object: nil,
            userInfo: nil
        )

        // Save current audio route state before reset if preservation is enabled
        var wasSpeakerActive = false
        if preserveSpeakerState {
            if let forcedState = forceSpeakerState {
                // Use the forced speaker state (saved at network change time)
                wasSpeakerActive = forcedState
                Logger.log.i(message: "[ACM_RESET] Peer:: Using forced speaker state from network change: \(wasSpeakerActive)")
            } else {
                // Detect current speaker state
                let currentRoute = AVAudioSession.sharedInstance().currentRoute
                wasSpeakerActive = currentRoute.outputs.contains { $0.portType == .builtInSpeaker }
                Logger.log.i(message: "[ACM_RESET] Peer:: Detected current speaker state: \(wasSpeakerActive)")
            }
        }
        
        // For Unified Plan, get audio tracks from transceivers
        let audioTracks = connection.transceivers.compactMap { $0.sender.track as? RTCAudioTrack }
        let originalStates = audioTracks.map { $0.isEnabled }
        
        self.setTrackEnabled(RTCAudioTrack.self, isEnabled: false)
        usleep(50000)
        self.setTrackEnabled(RTCAudioTrack.self, isEnabled: true)

        // Execute mute/unmute sequence with 200ms intervals
        performMuteUnmuteSequence(audioTracks: audioTracks, originalStates: originalStates, step: 1, preserveSpeakerState: preserveSpeakerState, wasSpeakerActive: wasSpeakerActive)
    }
    
    /// Performs a mute/unmute sequence to reset audio buffers
    private func performMuteUnmuteSequence(audioTracks: [RTCAudioTrack], originalStates: [Bool], step: Int, preserveSpeakerState: Bool = true, wasSpeakerActive: Bool = false) {
        let totalSteps = 3 // Mute -> Unmute -> Mute -> Unmute (final)

        if step > totalSteps {
            // Sequence completed, restore original states
            for (index, track) in audioTracks.enumerated() {
                if index < originalStates.count {
                    track.isEnabled = originalStates[index]
                }
            }
            Logger.log.i(message: "[ACM_RESET] Peer:: AudioDeviceModule reset sequence completed - original states restored")

            // After completing mute/unmute sequence, reset RTCAudioSession buffers
            resetAVAudioSessionBuffers(preserveSpeakerState: preserveSpeakerState, wasSpeakerActive: wasSpeakerActive)
            return
        }

        let isMute = (step % 2 == 1) // Odd steps = mute, even steps = unmute
        let action = isMute ? "muting" : "unmuting"

        Logger.log.i(message: "[ACM_RESET] Peer:: AudioDeviceModule reset step \(step)/\(totalSteps) - \(action) audio tracks (Unified Plan)")
        
        // Apply mute/unmute to all audio tracks
        audioTracks.forEach { $0.isEnabled = !isMute }
        
        // Schedule next step after 200ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.performMuteUnmuteSequence(audioTracks: audioTracks, originalStates: originalStates, step: step + 1, preserveSpeakerState: preserveSpeakerState, wasSpeakerActive: wasSpeakerActive)
        }
    }
    
    /// Resets RTCAudioSession buffer duration to optimal values to prevent audio delay accumulation
    /// Executes 3 times consecutively with 300ms intervals to ensure complete buffer reset
    /// 
    /// - Parameter preserveSpeakerState: Whether to preserve the current speakerphone state during reset
    /// - Parameter wasSpeakerActive: Whether the speaker was active before the reset
    private func resetAVAudioSessionBuffers(preserveSpeakerState: Bool = true, wasSpeakerActive: Bool = false) {
        Logger.log.i(message: "[ACM_RESET] Peer:: Starting 3-phase RTCAudioSession reset to clear accumulated buffers (preserveSpeaker: \(preserveSpeakerState), wasSpeakerActive: \(wasSpeakerActive))")
        
        // Execute reset 3 times with 300ms intervals
        for attempt in 1...3 {
            let delay = TimeInterval(attempt - 1) * 0.3 // 0ms, 300ms, 600ms
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.performSingleAudioSessionReset(attempt: attempt, preserveSpeakerState: preserveSpeakerState, wasSpeakerActive: wasSpeakerActive, isLastAttempt: attempt == 3)
            }
        }
    }
    
    /// Performs a single RTCAudioSession reset attempt
    /// 
    /// - Parameter attempt: The current attempt number (1-3)
    /// - Parameter preserveSpeakerState: Whether to preserve the current speakerphone state during reset
    /// - Parameter wasSpeakerActive: Whether the speaker was active before the reset
    /// - Parameter isLastAttempt: Whether this is the final attempt (used for speaker restoration)
    private func performSingleAudioSessionReset(attempt: Int, preserveSpeakerState: Bool = true, wasSpeakerActive: Bool = false, isLastAttempt: Bool = false) {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            Logger.log.i(message: "[ACM_RESET] Peer:: RTCAudioSession reset attempt \(attempt)/3")
            
            // Use RTCAudioSession for WebRTC-specific audio configuration
            let rtcAudioSession = RTCAudioSession.sharedInstance()
            
            rtcAudioSession.lockForConfiguration()
            defer {
                rtcAudioSession.unlockForConfiguration()
            }
            
            do {
                // Deactivate audio session first
                try rtcAudioSession.setActive(false)
                rtcAudioSession.isAudioEnabled = false
                
                // Brief pause to allow complete deactivation
                usleep(50000) // 50ms pause
                
                // Set optimal buffer duration for real-time audio (20ms)
                // This prevents iOS from using large buffers that cause delay
                try rtcAudioSession.setPreferredIOBufferDuration(0.02) // 20ms
                
                // Set preferred sample rate for WebRTC compatibility
                try rtcAudioSession.setPreferredSampleRate(16000.0)
                
                // Set preferred number of channels for mono audio (more efficient for voice)
                try rtcAudioSession.setPreferredInputNumberOfChannels(1)
                try rtcAudioSession.setPreferredOutputNumberOfChannels(1)
                
                // Configure WebRTC audio session
                let configuration = RTCAudioSessionConfiguration.webRTC()

                // Build category options - include .defaultToSpeaker if speaker should be active
                var categoryOptions: AVAudioSession.CategoryOptions = [
                    .duckOthers,
                    .allowBluetooth,
                ]

                if preserveSpeakerState && wasSpeakerActive {
                    categoryOptions.insert(.defaultToSpeaker)
                    Logger.log.i(message: "[ACM_RESET] Peer:: Adding .defaultToSpeaker to audio session configuration (wasSpeakerActive: \(wasSpeakerActive))")
                }

                configuration.categoryOptions = categoryOptions

                do {
                    try rtcAudioSession.setConfiguration(configuration)
                    Logger.log.i(message: "[ACM_RESET] Peer:: RTCAudioSession configured with options: \(categoryOptions)")
                } catch {
                    Logger.log.w(message: "[ACM_RESET] Peer:: Failed to set RTCAudioSession configuration on attempt \(attempt): \(error.localizedDescription)")
                }

                usleep(50000) // 50ms pause

                // Activate the session with new settings
                try rtcAudioSession.setActive(true)
                rtcAudioSession.isAudioEnabled = true

                Logger.log.i(message: "[ACM_RESET] Peer:: RTCAudioSession reset attempt \(attempt)/3 completed - IOBufferDuration: 20ms, SampleRate: 16kHz, Channels: 1")

                // Notify TxClient when the last reset completes
                if isLastAttempt && preserveSpeakerState {
                    // Notify TxClient to restore speaker if needed (on main thread)
                    DispatchQueue.main.async {
                        Logger.log.i(message: "[ACM_RESET] Peer:: ACM reset completed - notifying TxClient (wasSpeakerActive: \(wasSpeakerActive))")
                        NotificationCenter.default.post(
                            name: NSNotification.Name(InternalConfig.NotificationNames.acmResetCompleted),
                            object: nil,
                            userInfo: ["restoreSpeakerphone": wasSpeakerActive, "wasSpeakerActive": wasSpeakerActive]
                        )
                    }
                }

            } catch {
                Logger.log.e(message: "[ACM_RESET] Peer:: Failed to reset RTCAudioSession buffers on attempt \(attempt): \(error.localizedDescription)")
            }
        }
    }
    
}
// MARK: -RTCPeerConnectionDelegate
/**
 Here we receive the RTCPeer connection events.
 */
extension Peer : RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        let state = stateChanged.telnyx_to_string()
        onSignalingStateChange?(stateChanged, peerConnection)
        onSignalingStateChangeForLog?(stateChanged)
        Logger.log.i(message: "Peer:: connection didChange state: [\(state)]")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        onAddStream?(stream)
        Logger.log.i(message: "Peer:: connection didAdd: \(stream)")
        
        // Assign the remote stream for audio visualization
        self._remoteStream = stream
        
        if stream.videoTracks.count > 0 {
            self.remoteVideoTrack = stream.videoTracks[0]
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        onRemoveStream?(stream)
        Logger.log.i(message: "Peer:: connection didRemove \(stream)")
        
        // Clear the remote stream reference when removed
        if self._remoteStream == stream {
            self._remoteStream = nil
        }
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        onNegotiationNeeded?()
        Logger.log.i(message: "Peer:: connection should negotiate")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        onIceConnectionChange?(newState)
        onIceConnectionStateChange?(newState)
        Logger.log.i(message: "Peer:: connection didChange ICE connection state: [\(newState.telnyx_to_string().uppercased())]")
        
        // Track ICE connection state changes for benchmarking
        if CallTimingBenchmark.isRunning() {
            switch newState {
            case .checking:
                CallTimingBenchmark.mark(CallBenchmarkMilestone.iceStateChecking)
            case .connected:
                CallTimingBenchmark.mark(CallBenchmarkMilestone.iceStateConnected)
            case .completed:
                CallTimingBenchmark.mark(CallBenchmarkMilestone.iceStateCompleted)
            case .failed:
                CallTimingBenchmark.mark(CallBenchmarkMilestone.iceStateFailed)
            case .disconnected:
                CallTimingBenchmark.mark(CallBenchmarkMilestone.iceStateDisconnected)
            case .closed:
                CallTimingBenchmark.mark(CallBenchmarkMilestone.iceStateClosed)
            default:
                break
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState) {
        Logger.log.i(message: "Peer:: connection didChange peer connection state: [\(newState.telnyx_to_string().uppercased())]")
        
        // Track peer connection state changes for benchmarking
        if CallTimingBenchmark.isRunning() {
            switch newState {
            case .connecting:
                CallTimingBenchmark.mark(CallBenchmarkMilestone.peerStateConnecting)
            case .connected:
                CallTimingBenchmark.mark(CallBenchmarkMilestone.peerStateConnected)
                // End benchmarking when peer connection is established
                CallTimingBenchmark.end()
            case .disconnected:
                CallTimingBenchmark.mark(CallBenchmarkMilestone.peerStateDisconnected)
            case .failed:
                CallTimingBenchmark.mark(CallBenchmarkMilestone.peerStateFailed)
            case .closed:
                CallTimingBenchmark.mark(CallBenchmarkMilestone.peerStateClosed)
            default:
                break
            }
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        onIceGatheringChange?(newState)
        onIceGatheringStateChangeForLog?(newState)
        Logger.log.s(message: "[TRICKLE-ICE] Peer:: ICE gathering state changed to: [\(newState.telnyx_to_string().uppercased())] (useTrickleIce: \(useTrickleIce), callId: \(callId ?? "nil"))")
        
        // Track ICE gathering state changes for benchmarking
        if CallTimingBenchmark.isRunning() {
            switch newState {
            case .new:
                CallTimingBenchmark.mark(CallBenchmarkMilestone.iceGatheringNew)
            case .gathering:
                CallTimingBenchmark.mark(CallBenchmarkMilestone.iceGatheringGathering)
            case .complete:
                CallTimingBenchmark.mark(CallBenchmarkMilestone.iceGatheringComplete)
            @unknown default:
                break
            }
        }

        // Send end of candidates signal when ICE gathering is complete for trickle ICE
        if newState == .complete && useTrickleIce {
            Logger.log.i(message: "[TRICKLE-ICE] Peer:: ICE gathering COMPLETE - sending end of candidates signal")
            sendEndOfCandidates()
        }

        // Log ICE gathering state changes during ICE restart
        if self.isIceRestarting {
            Logger.log.i(message: "[TRICKLE-ICE] Peer:: ICE gathering state during restart: \(newState.telnyx_to_string())")
            // If ICE gathering is complete during ICE restart, trigger completion
            if newState == .complete, let completion = self.iceRestartCompletion {
                self.iceRestartCompletion = nil
                self.createFinalOfferWithCandidates(completion: completion)
            }
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        Logger.log.i(message: "[TRICKLE-ICE] Peer:: ICE candidate generated - sdpMid: \(candidate.sdpMid ?? "nil"), sdpMLineIndex: \(candidate.sdpMLineIndex)")
        
        // Mark first ICE candidate for benchmarking
        CallTimingBenchmark.markFirstCandidate()

        // For Trickle ICE, we always send candidates - don't skip based on negotiationEnded
        if !useTrickleIce {
            // Traditional mode: check if negotiation has ended or connection is established
            if !isIceRestarting {
                // Check if the negotiation has already ended.
                // If true, we avoid adding new ICE candidates since it's no longer necessary.
                if negotiationEnded {
                    Logger.log.i(message: "[TRICKLE-ICE] Peer:: Skipping candidate - negotiation already ended (traditional mode)")
                    return
                }

                // Check if the connection is already established (state is 'connected').
                // If true, we skip adding new ICE candidates to prevent redundant additions.
                if peerConnection.connectionState == .connected {
                    Logger.log.i(message: "[TRICKLE-ICE] Peer:: Skipping candidate - connection already established")
                    return
                }
            } else {
                // Check if we already have enough candidates and should stop gathering
                if let localDescription = peerConnection.localDescription {
                    let currentCandidateCount = localDescription.sdp.components(separatedBy: "a=candidate:").count - 1
                    if currentCandidateCount >= 3 { // We have enough candidates
                        Logger.log.i(message: "[TRICKLE-ICE] Peer:: Skipping candidate - already have \(currentCandidateCount) candidates during ICE restart")
                        // Don't add more candidates to avoid overwhelming the server
                        return
                    }
                }
            }
        }

        // We call the callback when the iceCandidate is added
        onIceCandidate?(candidate)

        // Handle trickle ICE - send candidates individually as they are discovered
        if useTrickleIce {
            if isAnswering && !answerSent {
                // Answering side: Queue candidate until ANSWER is sent
                queuedCandidates.append(candidate)
                Logger.log.i(message: "[TRICKLE-ICE] Peer:: ICE candidate queued for answering side (ANSWER not sent yet): \(candidate.sdpMid ?? "nil")")
            } else {
                // Calling side OR answering side after ANSWER sent: Send immediately
                Logger.log.i(message: "[TRICKLE-ICE] Peer:: Trickle ICE enabled - sending candidate individually")
                sendTrickleCandidate(candidate)

                // Start/restart the end-of-candidates timer when sending candidates
                // Only start timer when candidate is actually SENT, not when queued
                Logger.log.i(message: "[TRICKLE-ICE] Peer:: Starting/restarting negotiation timer for endOfCandidates detection")
                self.startNegotiation(peerConnection: connection!, didGenerate: candidate)
            }
        } else {
            Logger.log.i(message: "[TRICKLE-ICE] Peer:: Trickle ICE disabled - candidate will be included in SDP")
        }

        // Note: We don't manually add ICE candidates with connection.add() because:
        // 1. For offers, candidates are automatically included in the local SDP
        // 2. For answers, candidates are automatically included in the answer SDP
        // 3. We use Trickle ICE through signaling, not manual candidate addition
        // Attempting to add candidates manually causes "The remote description was null" error

        // Start negotiation timer for traditional ICE mode:
        // Only start timer when an ICE candidate from the configured STUN or TURN server is gathered
        if !useTrickleIce {

            gatheredICECandidates.append(candidate.serverUrl ?? "")

            // Start negotiation if an ICE candidate from the configured STUN or TURN server is gathered.
            // Extract server URLs from the configured ice servers for this peer connection
            let configuredServerUrls = configuredIceServers.flatMap { $0.urlStrings }

            if gatheredICECandidates.contains(where: { gatheredUrl in
                configuredServerUrls.contains { configuredUrl in
                    // Extract the base URL without transport parameters for comparison
                    let gatheredBase = gatheredUrl.components(separatedBy: "?").first ?? gatheredUrl
                    let configuredBase = configuredUrl.components(separatedBy: "?").first ?? configuredUrl
                    return gatheredBase == configuredBase
                }
            }) {
                Logger.log.i(message: "Peer:: Valid ICE candidate found from configured server - starting negotiation (traditional mode)")
                self.startNegotiation(peerConnection: connection!, didGenerate: candidate)
            }
        }
      
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        onRemoveIceCandidates?(candidates)
        Logger.log.i(message: "Peer:: connection didRemove [RTCIceCandidate]: \(candidates)")
    }
    
    /// Sends individual ICE candidate via trickle ICE signaling
    private func sendTrickleCandidate(_ candidate: RTCIceCandidate) {
        guard let socket = socket else {
            Logger.log.w(message: "[TRICKLE-ICE] Peer:: Cannot send trickle candidate - socket is nil")
            return
        }

        guard let sessionId = sessionId else {
            Logger.log.w(message: "[TRICKLE-ICE] Peer:: Cannot send trickle candidate - sessionId is nil")
            return
        }

        // Use callId (from INVITE) instead of callLegID (from backend response)
        // This ensures the candidate messages use the same callID as the INVITE message
        guard let candidateCallId = callId else {
            Logger.log.w(message: "[TRICKLE-ICE] Peer:: Cannot send trickle candidate - callId is nil")
            return
        }

        Logger.log.i(message: "[TRICKLE-ICE] Peer:: Preparing to send candidate - callId: \(candidateCallId), sessionId: \(sessionId), sdpMid: \(candidate.sdpMid ?? "nil"), sdpMLineIndex: \(candidate.sdpMLineIndex)")

        // Clean the candidate string to remove WebRTC-specific extensions
        let cleanedCandidateString = SdpUtils.cleanCandidateString(candidate.sdp)

        let candidateMessage = CandidateMessage(
            callId: candidateCallId,
            sessionId: sessionId,
            candidate: cleanedCandidateString,
            sdpMid: candidate.sdpMid ?? "",
            sdpMLineIndex: Int32(candidate.sdpMLineIndex)
        )

        if let message = candidateMessage.encode() {
            socket.sendMessage(message: message)
            Logger.log.s(message: "[TRICKLE-ICE] Peer:: ✅ Sent trickle candidate via socket")
            Logger.log.i(message: "[TRICKLE-ICE] Peer:: Candidate details: \(cleanedCandidateString.prefix(100))...")
        } else {
            Logger.log.e(message: "[TRICKLE-ICE] Peer:: ❌ Failed to encode candidate message")
        }
    }

    /// NOTE: This method is no longer needed as candidates are sent immediately
    /// using callId from INVITE instead of waiting for callLegID from backend
    @available(*, deprecated, message: "No longer needed - candidates are sent immediately")
    internal func flushPendingTrickleCandidates() {
        Logger.log.i(message: "[TRICKLE-ICE] Peer:: flushPendingTrickleCandidates() - deprecated, no longer needed")
    }

    /// Flushes all queued ICE candidates after ANSWER is sent.
    /// This is called when the answering side sends the ANSWER message.
    /// Prevents race conditions where candidates arrive before the ANSWER.
    internal func flushQueuedCandidatesAfterAnswer() {
        guard useTrickleIce, isAnswering else {
            Logger.log.i(message: "[TRICKLE-ICE] Peer:: Not flushing - trickleIce: \(useTrickleIce), isAnswering: \(isAnswering)")
            return
        }

        Logger.log.i(message: "[TRICKLE-ICE] Peer:: Flushing \(queuedCandidates.count) queued candidates after ANSWER sent")

        let hadCandidates = !queuedCandidates.isEmpty

        // Send all queued candidates
        for candidate in queuedCandidates {
            sendTrickleCandidate(candidate)
            Logger.log.i(message: "[TRICKLE-ICE] Peer:: Flushed queued candidate: \(candidate.sdpMid ?? "nil")")
        }

        // Clear queue and mark answer as sent
        queuedCandidates.removeAll()
        answerSent = true

        // Start/restart timer after flushing candidates (if there were any)
        if hadCandidates, let connection = connection {
            // Use a dummy candidate to restart the timer - we just need to trigger the timer mechanism
            // The actual candidate data doesn't matter for the timer logic
            let dummyCandidate = RTCIceCandidate(sdp: "", sdpMLineIndex: 0, sdpMid: nil)
            self.startNegotiation(peerConnection: connection, didGenerate: dummyCandidate)
        }

        Logger.log.i(message: "[TRICKLE-ICE] Peer:: Candidate flush completed, answerSent = true")
    }
    
    /// Sends end of candidates signal for trickle ICE
    private func sendEndOfCandidates() {
        guard let socket = socket, useTrickleIce else {
            Logger.log.i(message: "[TRICKLE-ICE] Peer:: Skipping end of candidates - socket: \(socket != nil), useTrickleIce: \(useTrickleIce)")
            return
        }

        // Check if already sent to prevent duplicates
        guard !endOfCandidatesSent else {
            Logger.log.i(message: "[TRICKLE-ICE] Peer:: Skipping end of candidates - already sent for this session")
            return
        }

        guard let sessionId = sessionId else {
            Logger.log.w(message: "[TRICKLE-ICE] Peer:: Cannot send end of candidates - sessionId is nil")
            return
        }

        // Use callId (from INVITE) instead of callLegID (from backend response)
        // This ensures the endOfCandidates message uses the same callID as the INVITE and candidate messages
        guard let endCallId = callId else {
            Logger.log.w(message: "[TRICKLE-ICE] Peer:: Cannot send end of candidates - callId is nil")
            return
        }

        Logger.log.i(message: "[TRICKLE-ICE] Peer:: Preparing to send END OF CANDIDATES signal for callId: \(endCallId), sessionId: \(sessionId)")

        let endOfCandidatesMessage = EndOfCandidatesMessage(callId: endCallId, sessionId: sessionId)

        if let message = endOfCandidatesMessage.encode() {
            socket.sendMessage(message: message)
            endOfCandidatesSent = true
            Logger.log.s(message: "[TRICKLE-ICE] Peer:: ✅ Sent END OF CANDIDATES signal via socket")
            Logger.log.i(message: "[TRICKLE-ICE] Peer:: Message payload: \(message)")
        } else {
            Logger.log.e(message: "[TRICKLE-ICE] Peer:: ❌ Failed to encode end of candidates message")
        }
    }

    /// Handles incoming remote ICE candidate from trickle ICE signaling
    /// - Parameters:
    ///   - candidateString: The ICE candidate string
    ///   - sdpMid: The media stream identification
    ///   - sdpMLineIndex: The media line index
    func handleRemoteCandidate(candidateString: String, sdpMid: String?, sdpMLineIndex: Int32) {
        guard let connection = connection else {
            Logger.log.w(message: "[TRICKLE-ICE] Peer:: Cannot add remote candidate - connection is nil")
            return
        }

        guard useTrickleIce else {
            Logger.log.w(message: "[TRICKLE-ICE] Peer:: Ignoring remote candidate - trickle ICE is disabled")
            return
        }

        Logger.log.i(message: "[TRICKLE-ICE] Peer:: Received remote candidate - sdpMid: \(sdpMid ?? "nil"), sdpMLineIndex: \(sdpMLineIndex)")
        Logger.log.i(message: "[TRICKLE-ICE] Peer:: Candidate: \(candidateString.prefix(100))...")

        let candidate = RTCIceCandidate(sdp: candidateString, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)

        connection.add(candidate) { error in
            if let error = error {
                Logger.log.e(message: "[TRICKLE-ICE] Peer:: ❌ Failed to add remote candidate: \(error.localizedDescription)")
            } else {
                Logger.log.s(message: "[TRICKLE-ICE] Peer:: ✅ Successfully added remote candidate")
            }
        }
    }

    /// Handles end of remote candidates signal from trickle ICE signaling
    func handleEndOfRemoteCandidates() {
        Logger.log.i(message: "[TRICKLE-ICE] Peer:: Received END OF REMOTE CANDIDATES signal")
        // In WebRTC, we don't need to do anything special when remote candidates end
        // The connection will complete once all candidates have been processed
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        onDataChannel?(dataChannel)
        Logger.log.i(message: "Peer:: connection didOpen RTCDataChannel: \(dataChannel)")
    }
}

