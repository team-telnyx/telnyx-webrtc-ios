//
//  Peer.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 03/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation
import WebRTC

protocol PeerDelegate: AnyObject {
    func onNegotiationEnded(sdp: RTCSessionDescription?)
}

class Peer : NSObject, WebRTCEventHandler {

    private let audioQueue = DispatchQueue(label: "audio")
    private let NEGOTIATION_TIMOUT = 0.3 //time in milliseconds
    private let AUDIO_TRACK_ID = "audio0"
    private let VIDEO_TRACK_ID = "video0"
    //TODO: REMOVE THIS FOR V1
    private let VIDEO_DEMO_LOCAL_VIDEO = "local_video_streaming.mp4"
    private var gatheredICECandidates: [String] = []
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

    //ICE negotiation
    private var negotiationTimer: Timer?
    private var negotiationEnded: Bool = false

    // WEBRTC STATS
    var onSignalingStateChange: ((RTCSignalingState, RTCPeerConnection) -> Void)?
    var onAddStream: ((RTCMediaStream) -> Void)?
    var onRemoveStream: ((RTCMediaStream) -> Void)?
    var onNegotiationNeeded: (() -> Void)?
    var onIceConnectionChange: ((RTCIceConnectionState) -> Void)?
    var onIceGatheringChange: ((RTCIceGatheringState) -> Void)?
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
    
    // The `RTCPeerConnectionFactory` is in charge of creating new RTCPeerConnection instances.
    // A new RTCPeerConnection should be created every new call, but the factory is shared.
    private static let factory: RTCPeerConnectionFactory = {
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
                  isAttach: Bool = false) {
        let config = RTCConfiguration()
        config.iceServers = iceServers

        // Unified plan is more superior than planB
        config.sdpSemantics = .unifiedPlan
        config.bundlePolicy = .maxCompat
        

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

        // let's support Audio first.
        let audioTrack = self.createAudioTrack()
        self.localAudioTrack = audioTrack
        self.connection?.add(audioTrack, streamIds: [streamId])
        self.muteUnmuteAudio(mute: false)
    }

    /**
     iOS specific: we need to configure the device AudioSession.
     */
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
                
                // Configure audio session for VoIP calls
                try self.rtcAudioSession.setCategory(AVAudioSession.Category(rawValue: AVAudioSession.Category.playAndRecord.rawValue))
                try self.rtcAudioSession.setMode(AVAudioSession.Mode.voiceChat)
                
                // Enable mixing with other audio sessions
                try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord, 
                                                   options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers])
                
                // Set preferred audio I/O buffer duration
                try self.rtcAudioSession.setPreferredIOBufferDuration(0.005)
                
                // Set preferred sample rate
                try self.rtcAudioSession.setPreferredSampleRate(44100.0)
                
                Logger.log.i(message: "Peer:: AVAudioSession configured successfully")
            } catch let error {
                Logger.log.e(message: "Peer:: Error configuring AVAudioSession: \(error.localizedDescription)")
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
        
            
        //Set gathered candidates to 
        
        //Restart the negotiation timer
        self.negotiationTimer?.invalidate()
        self.negotiationTimer = nil
        DispatchQueue.main.async {
            self.negotiationTimer = Timer.scheduledTimer(withTimeInterval: self.NEGOTIATION_TIMOUT, repeats: false) { timer in
                // Check if the negotiation process has ended to avoid duplicated calls to the delegate method.
                if self.negotiationEnded {
                    // Means we have an active call for this peer object
                    if self.connection?.connectionState == .disconnected {
                        // Reconnect if the peer is disconnected
                        self.socket?.delegate?.onSocketReconnectSuggested()
                    }
                    Logger.log.w(message: "ICE negotiation has ended:: For Peer")
                    return
                }
                self.negotiationTimer?.invalidate()
                self.negotiationEnded = true
                // At this moment we should have at least one ICE candidate.
                // Lets stop the ICE negotiation process and call the apropiate delegate
                self.delegate?.onNegotiationEnded(sdp: peerConnection.localDescription)
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
    func muteUnmuteAudio(mute: Bool) {
        //GetTransceivers is only supported with Unified Plan SdpSemantics.
        //PlanB doesn't have support to access transeivers, so we need to use the storedAudio track
        if self.connection?.configuration.sdpSemantics == .planB {
            self.connection?.senders
                .compactMap { return $0.track as? RTCAudioTrack } // Search for Audio track
                .forEach {
                    $0.isEnabled = !mute // disable RTCAudioTrack
                }
        } else {
            self.setTrackEnabled(RTCAudioTrack.self, isEnabled: !mute)
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
        if stream.videoTracks.count > 0 {
            self.remoteVideoTrack = stream.videoTracks[0]
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        onRemoveStream?(stream)
        Logger.log.i(message: "Peer:: connection didRemove \(stream)")
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        onNegotiationNeeded?()
        Logger.log.i(message: "Peer:: connection should negotiate")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        onIceConnectionChange?(newState)
        Logger.log.i(message: "Peer:: connection didChange ICE connection state: [\(newState.telnyx_to_string().uppercased())]")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        onIceGatheringChange?(newState)
        Logger.log.s(message: "Peer:: connection didChange ICE gathering state: [\(newState.telnyx_to_string().uppercased())]")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        Logger.log.i(message: "Peer:: connection didGenerate RTCIceCandidate: \(candidate)")

        // Check if the negotiation has already ended.
        // If true, we avoid adding new ICE candidates since it's no longer necessary.
        if negotiationEnded {
            Logger.log.i(message: "Peer:: negotiation marked as ENDED. Skipping candidate: [\(candidate)]")
            return
        }

        // Check if the connection is already established (state is 'connected').
        // If true, we skip adding new ICE candidates to prevent redundant additions.
        if peerConnection.connectionState == .connected {
            Logger.log.i(message: "Peer:: connection state is CONNECTED. Skipping candidate: [\(candidate)]")
            return
        }

        // We call the callback when the iceCandidate is added
        onIceCandidate?(candidate)
        // Add the generated ICE candidate to the peer connection.
        // This helps populate the local SDP with the ICE candidate information.
        connection?.add(candidate, completionHandler: { error in
            if let error = error {
                Logger.log.e(message: "Peer:: Failed to add RTCIceCandidate: \(error) for candidate: \(candidate)")
            } else {
                Logger.log.i(message: "Peer:: Successfully added RTCIceCandidate: \(candidate)")
            }
        })
        
        // Log the server URL of the generated ICE candidate (if available).
        Logger.log.i(message: "Peer:: serverUrl for RTCIceCandidate: \(String(describing: candidate.serverUrl))")
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
