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
    
    /// Timeout duration for ICE negotiation in seconds
    private let NEGOTIATION_TIMOUT = 0.3
    
    /// Identifier for the audio track in WebRTC connection
    private let AUDIO_TRACK_ID = "audio0"
    
    /// Identifier for the video track in WebRTC connection
    private let VIDEO_TRACK_ID = "video0"
    
    /// Local video file used for testing in simulator environment
    private let VIDEO_DEMO_LOCAL_VIDEO = "local_video_streaming.mp4"
    
    /// Collection of gathered ICE candidates during connection setup
    internal var gatheredICECandidates: [String] = []
    
    /// Socket connection for signaling with the WebRTC server
    var socket: Socket?


    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                                   kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueFalse]

    weak var delegate: PeerDelegate?
    var connection : RTCPeerConnection?

    //Audio
    private var localAudioTrack: RTCAudioTrack?
    private let rtcAudioSession =  RTCAudioSession.sharedInstance()

    //Video
    private var videoCapturer: RTCVideoCapturer?
    private var localVideoTrack: RTCVideoTrack?
    private var remoteVideoTrack: RTCVideoTrack?
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
                  forceRelayCandidate: Bool = false) {
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

    // MARK: Signaling OFFER
    func offer(completion: @escaping (_ sdp: RTCSessionDescription?, _ error: Error?) -> Void) {

        let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains,
                                             optionalConstraints: nil)
        self.negotiationEnded = false
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
                completion(sdp, nil)
            })
        }
    }


    // MARK: Signaling ANSWER
    func answer(callLegId: String, completion: @escaping (_ sdp: RTCSessionDescription?, _ error: Error?) -> Void) {
        self.negotiationEnded = false
        let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains,
                                             optionalConstraints: nil)
        self.callLegID = callLegId
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
                completion(sdp, nil)
            })
        }
    }

    /**
     This code should be started when the first ICE candidate is created.
     After that, each time a new ICE candidate should restart this timer until: NO more ICE candidates are been generated, or it took too longer to generate
     the next ICE Candidate.
     We need only Once ICE candidate in the SDP in order to start a webrtc connection.
     */
    fileprivate func startNegotiation(peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        Logger.log.i(message: "Peer:: ICE negotiation updated.")
        
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
        self.onIceCandidate = nil
        self.onRemoveIceCandidates = nil
        self.onDataChannel = nil
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
    func resetAudioDeviceModule(preserveSpeakerState: Bool = true) {
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
            let currentRoute = AVAudioSession.sharedInstance().currentRoute
            wasSpeakerActive = currentRoute.outputs.contains { $0.portType == .builtInSpeaker }
            Logger.log.i(message: "[ACM_RESET] Peer:: Preserving audio route state - Speaker was active: \(wasSpeakerActive)")
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
                configuration.categoryOptions = [
                    .duckOthers,
                    .allowBluetooth,
                ]
                
                do {
                    try rtcAudioSession.setConfiguration(configuration)
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
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        onIceGatheringChange?(newState)
        Logger.log.s(message: "Peer:: connection didChange ICE gathering state: [\(newState.telnyx_to_string().uppercased())]")
        
        // Log ICE gathering state changes during ICE restart
        if self.isIceRestarting {
            // If ICE gathering is complete during ICE restart, trigger completion
            if newState == .complete, let completion = self.iceRestartCompletion {
                self.iceRestartCompletion = nil
                self.createFinalOfferWithCandidates(completion: completion)
            }
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        // During ICE restart, we should allow candidates even when connected
        if !isIceRestarting {
            // Check if the negotiation has already ended.
            // If true, we avoid adding new ICE candidates since it's no longer necessary.
            if negotiationEnded {
                return
            }

            // Check if the connection is already established (state is 'connected').
            // If true, we skip adding new ICE candidates to prevent redundant additions.
            if peerConnection.connectionState == .connected {
                return
            }
        } else {
            // Check if we already have enough candidates and should stop gathering
            if let localDescription = peerConnection.localDescription {
                let currentCandidateCount = localDescription.sdp.components(separatedBy: "a=candidate:").count - 1
                if currentCandidateCount >= 3 { // We have enough candidates
                    // Don't add more candidates to avoid overwhelming the server
                    return
                }
            }
        }

        // We call the callback when the iceCandidate is added
        onIceCandidate?(candidate)

        // Note: We don't manually add ICE candidates with connection.add() because:
        // 1. For offers, candidates are automatically included in the local SDP
        // 2. For answers, candidates are automatically included in the answer SDP
        // 3. We use Trickle ICE through signaling, not manual candidate addition
        // Attempting to add candidates manually causes "The remote description was null" error

        gatheredICECandidates.append(candidate.serverUrl ?? "")

        // Start negotiation if an ICE candidate from the configured STUN or TURN server is gathered.
        if gatheredICECandidates.contains(InternalConfig.stunServer) ||
            gatheredICECandidates.contains(InternalConfig.turnServer) {
            
            self.startNegotiation(peerConnection: connection!, didGenerate: candidate)
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        onRemoveIceCandidates?(candidates)
        Logger.log.i(message: "Peer:: connection didRemove [RTCIceCandidate]: \(candidates)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        onDataChannel?(dataChannel)
        Logger.log.i(message: "Peer:: connection didOpen RTCDataChannel: \(dataChannel)")
    }
}

