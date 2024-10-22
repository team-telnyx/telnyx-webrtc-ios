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
    //TODO: Rename this to "negotiationDidEnded"
    func onICECandidate(sdp: RTCSessionDescription?, iceCandidate: RTCIceCandidate)
}

class Peer : NSObject {

    private let audioQueue = DispatchQueue(label: "audio")
    private let NEGOTIATION_TIMOUT = 0.3 //time in milliseconds
    private let AUDIO_TRACK_ID = "audio0"
    private let VIDEO_TRACK_ID = "video0"
    //TODO: REMOVE THIS FOR V1
    private let VIDEO_DEMO_LOCAL_VIDEO = "local_video_streaming.mp4"
    private var gatheredICECandidates:[String] = []
    var socket:Socket? 
    private let timeStamp = Timestamp()

    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue, kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueFalse]

    weak var delegate: PeerDelegate?
    var connection : RTCPeerConnection?

    //Audio
    private var localAudioTrack: RTCAudioTrack?
    private let rtcAudioSession =  RTCAudioSession.sharedInstance()

    //Video
    private var videoCapturer: RTCVideoCapturer?
    private var localVideoTrack: RTCVideoTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    private var callLegID: String?

    //Data channel
    private var localDataChannel: RTCDataChannel?
    private var remoteDataChannel: RTCDataChannel?

    //ICE negotiation
    private var negotiationTimer: Timer?
    private var negotiationEnded: Bool = false

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

    required init(iceServers: [RTCIceServer],isAttach:Bool = false) {
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
        if(!isAttach){
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
                try self.rtcAudioSession.setCategory(AVAudioSession.Category(rawValue: AVAudioSession.Category.playAndRecord.rawValue))
                try self.rtcAudioSession.setMode(AVAudioSession.Mode.voiceChat)
                Logger.log.i(message: "Peer:: Configuring AVAudioSession configured")
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
    func answer(callLegId:String,completion: @escaping (_ sdp: RTCSessionDescription?, _ error: Error?) -> Void) {
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
    
    private var timer: DispatchSourceTimer?

    private var statsEvent = [String: Any]()
    private var inboundStats = [Any]()
    private var outBoundStats = [Any]()
    private var statsData = [String: Any]()
    private var audio = [String: [Any]]()
    private var candidatePairs =  [Any]()
    private let CANDIDATE_PAIR_LIMIT = 5
    private var debugStatsId = UUID.init()
    private var debugReportStarted = false
    private var isDebugStats = false

        func startTimer() {
            isDebugStats = true
            let queue = DispatchQueue.main
            timer = DispatchSource.makeTimerSource(queue: queue)
            timer?.schedule(deadline: .now(), repeating: 2.0)
            timer?.setEventHandler { [weak self] in
                self?.executeTask()
            }
            timer?.resume()
        }

        func stopTimer() {
            statsData["audio"] = audio
            statsEvent["data"] = statsData
            statsEvent.printJson()
            timer?.cancel()
            timer = nil
            sendStatsType(id: debugStatsId, type: StatsType.STOP_STARTS.rawValue)
            debugReportStarted = false
            isDebugStats = false
        }
    
    /// To receive INVITE message after Push Noficiation is Received. Send attachCall Command
    fileprivate func sendStats(id:UUID,data:[String:Any]) {
        Logger.log.e(message: "TxClient:: Sending Stats")
        let statsMessage = StatsMessage(reportID: id.uuidString.lowercased(), reportData: data)
        self.socket?.sendMessage(message: statsMessage.encode())
    }
    
    fileprivate func sendStatsType(id:UUID,type:String) {
        Logger.log.e(message: "TxClient:: Sending Stats \(type)")
        let statsMessage = InitiateOrStopStats(type: type, reportID: id.uuidString.lowercased())
        self.socket?.sendMessage(message: statsMessage.encode())
    }
    
    

        private func executeTask() {
            print("Task executed at \(Date())")
            
            
            if(!debugReportStarted){
                debugStatsId = UUID.init()
                sendStatsType(id: debugStatsId, type: StatsType.START_STARTS.rawValue)
                debugReportStarted = true
            }
          
            statsEvent["event"] = "stats"
            statsEvent["tag"] = "stats"
            statsEvent["peerId"] = "stats"
            statsEvent["connectionId"] = self.callLegID ?? ""
            statsEvent["timeTaken"] = 1
            
            

            self.connection?.statistics(completionHandler: { reports in
                reports.statistics.forEach { report in
                    if(report.value.type == "inbound-rtp") {
                        //Logger.log.i(message: "Peer:: ICE negotiation updated. Report New: \(report.values)")
                        self.inboundStats.append(report.value.values)
                    }
                    if(report.value.type == "outbound-rtp") {
                        //Logger.log.i(message: "Peer:: ICE negotiation updated. Report New: \(report.values)")
                        self.outBoundStats.append(report.value.values)
                    }
                    if(report.value.type == "candidate-pair" && self.candidatePairs.count < self.CANDIDATE_PAIR_LIMIT) {
                        //Logger.log.i(message: "Peer:: ICE negotiation updated. Report New: \(report.values)")
                        self.candidatePairs.append(report.value.values)
                    }
                }
            })
            audio["outbound"] = outBoundStats
            audio["inbound"] = inboundStats
            statsData["audio"] = audio
            statsEvent["data"] = statsData
            statsEvent["timestamp"] = timeStamp.getTimestamp()

            if(inboundStats.count > 0 && outBoundStats.count > 0 && candidatePairs.count > 0){
                inboundStats.removeAll()
                outBoundStats.removeAll()
                candidatePairs.removeAll()
                statsData.removeAll()
                audio.removeAll()
                self.sendStats(id: debugStatsId, data: statsEvent)
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
                if (self.negotiationEnded) {
                    // Means we have an active call for this peer object
                    self.socket?.delegate?.onSocketReconnectSuggested()
                    Logger.log.w(message: "ICE negotiation has ended:: For Peer")
                    return
                }
                self.negotiationTimer?.invalidate()
                self.negotiationEnded = true
                // At this moment we should have at least one ICE candidate.
                // Lets stop the ICE negotiation process and call the apropiate delegate
                self.delegate?.onICECandidate(sdp: peerConnection.localDescription, iceCandidate: candidate)
                Logger.log.i(message: "Peer:: ICE negotiation ended.")
            }
        }
    }

    /// Close connection and release resources
    func dispose() {
        Logger.log.i(message: "Peer:: dispose()")
        if(isDebugStats){
            stopTimer()
        }
        
        //This should release all the connection resources
        //including audio / video streams
        self.connection?.close()
        self.delegate = nil

        self.localAudioTrack = nil
        self.localVideoTrack = nil
        self.localDataChannel = nil

        self.remoteVideoTrack = nil
        self.remoteDataChannel = nil
    }

}
// MARK: - Tracks handling
extension Peer {
    //DO NOT USE THIS FOR planB
    private func setTrackEnabled<T: RTCMediaStreamTrack>(_ type: T.Type, isEnabled: Bool) {
        self.connection?.transceivers
            .compactMap { return $0.sender.track as? T }
            .forEach { $0.isEnabled = isEnabled }
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
        var state = ""
        switch(stateChanged) {
            case .stable:
                state = "stable"
            case .haveLocalOffer:
                state = "haveLocalOffer"
            case .haveLocalPrAnswer:
                state = "haveLocalPrAnswer"
            case .haveRemoteOffer:
                state = "haveRemoteOffer"
            case .haveRemotePrAnswer:
                state = "haveRemotePrAnswer"
            case .closed:
                state = "closed"
            @unknown default:
                state = "unknown"
        }
        Logger.log.i(message: "Peer:: connection didChange state: [\(state.uppercased())]")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        Logger.log.i(message: "Peer:: connection didAdd: \(stream)")
        if stream.videoTracks.count > 0 {
            self.remoteVideoTrack = stream.videoTracks[0]
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
       // Logger.log.i(message: "Peer:: connection didRemove \(stream)")
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        Logger.log.i(message: "Peer:: connection should negotiate")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        var state = ""
        switch(newState) {
            case .checking:
                state = "checking"
            case .new:
                state = "new"
            case .connected:
                state = "connected"
               // self.configureAudioSession()
            case .completed:
                state = "completed"
            case .failed:
                state = "failed"
            case .disconnected:
                state = "disconnected"
            case .closed:
                state = "closed"
            case .count:
                state = "count"
            @unknown default:
                state = "unknown"
        }
        Logger.log.i(message: "Peer:: connection didChange RTCIceConnectionState [\(state.uppercased())]")    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        var state = ""
        switch(newState) {
            case .new:
                state = "new"
            case .gathering:
                state = "gathering"
            case .complete:
                state = "complete"
            @unknown default:
                state = "unknown"
        }
        Logger.log.s(message: "Peer:: connection didChange RTCIceGatheringState [\(state.uppercased())]")    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        Logger.log.i(message: "Peer:: connection didGenerate RCIceCandidate: \(candidate)")
        //once an ICE candidate is generated, let's added into the peerConnection so the ICE Candidate
        //information is added to the local SDP.

        
        connection?.add(candidate, completionHandler: { error in
            Logger.log.i(message: "Peer::add [RTCIceCandidate]: \(String(describing: error)) \(candidate) ")
        })
        
        Logger.log.i(message: "Peer::serverUrl [RTCIceCandidate]: \(String(describing: candidate.serverUrl))")
        gatheredICECandidates.append(candidate.serverUrl ?? "")
        
        if(gatheredICECandidates.contains(InternalConfig.stunServer) ||
            gatheredICECandidates.contains(InternalConfig.turnServer)){
            
            self.startNegotiation(peerConnection: connection!, didGenerate: candidate)
            
        }
        
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
     //   Logger.log.i(message: "Peer:: connection didRemove [RTCIceCandidate]: \(candidates)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        Logger.log.i(message: "Peer:: connection didOpen RTCDataChannel: \(dataChannel)")
    }
}
extension Dictionary {

    var json: String {
        let invalidJson = "Not a valid JSON"
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson
        } catch {
            return invalidJson
        }
    }

    func printJson() {
        print(json)
    }

}


private let PROTOCOL_VERSION: String = "2.0"



enum StatsType : String  {
    case STOP_STARTS = "debug_report_stop"
    case START_STARTS = "debug_report_start"
}

class InitiateOrStopStats {
    
    private var jsonMessage: [String: Any] = [String: Any]()
    let jsonrpc = PROTOCOL_VERSION
    var id: String = UUID.init().uuidString.lowercased()
    
    init(type:String,reportID:String){
        self.jsonMessage = [String: Any]()
        self.jsonMessage["jsonrpc"] = self.jsonrpc
        self.jsonMessage["id"] = self.id
        self.jsonMessage["debug_report_version"] = 1
        self.jsonMessage["type"] = type
        self.jsonMessage["debug_report_id"] = reportID
    }
    
    func encode() -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonMessage, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            Logger.log.e(message: "Message:: encode() error")
            return nil
        }
        return jsonString
    }
}


