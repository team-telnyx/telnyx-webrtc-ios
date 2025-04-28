import WebRTC
import Foundation

/// The WebRTCStatsReporter class collects and reports WebRTC statistics and events
/// to Telnyx's servers for debugging and quality monitoring purposes.
///
/// This reporter tracks various aspects of the WebRTC connection including:
/// - Audio statistics (inbound and outbound)
/// - ICE candidate information
/// - Connection state changes
/// - Media track events
/// - Network statistics
///
/// The reporter is enabled when the `debug` flag is set to true in the Call configuration.
/// Statistics are collected every 2 seconds and sent to Telnyx's servers for analysis.
///
/// ## Usage
/// ```swift
/// // Create a reporter instance
/// let reporter = WebRTCStatsReporter(socket: socket)
///
/// // Start reporting for a specific peer
/// reporter.startDebugReport(peerId: callId, peer: peerConnection)
///
/// // Stop reporting when done
/// reporter.dispose()
/// ```
///
/// The reporter also provides real-time call quality metrics through the `onStatsFrame` callback,
/// which can be used to monitor call quality in real-time.
class WebRTCStatsReporter {
    // MARK: - Properties
    /// Timer for periodic stats collection
    private var timer: DispatchSourceTimer?
    
    /// Unique identifier for the peer connection being monitored
    private var peerId: UUID?
    
    /// Unique identifier for this reporting session
    internal var reportId: UUID = UUID.init()
    
    /// Reference to the peer connection being monitored
    private weak var peer: Peer?
    
    /// Reference to the peer connection being monitored
    private weak var call: Call?
    
    /// Socket connection for sending stats to Telnyx servers
    weak var socket: Socket?
    
    /// Queue for handling message sending to avoid blocking the main thread
    private let messageQueue = DispatchQueue(label: "WebRTCStatsReporter.MessageQueue")
    
    /// Flag to track if stats reporting is paused due to socket disconnection or call state
    private var isReportingPaused: Bool = false
    
    /// Callback for real-time call quality metrics
    public var onStatsFrame: ((CallQualityMetrics) -> Void)?
    
    // MARK: - Initializer
    init(socket: Socket,reportId:UUID? = nil) {
        self.socket = socket
        self.reportId = reportId ?? UUID.init()
    }
    
    public func startDebugReport(peerId: UUID,
                                 call: Call) {
        
        self.peerId = peerId
        self.peer = call.peer
        self.call  = call
        self.isReportingPaused = false
        self.sendDebugReportStartMessage(id: self.reportId)
        
        // Connect the onStatsFrame callback to the Call's onCallQualityChange callback
        self.onStatsFrame = { [weak call] metrics in
            call?.onCallQualityChange?(metrics)
        }
        
        let delay = DispatchTime.now() + 0.2
        DispatchQueue.main.asyncAfter(deadline: delay) { [weak self] in
            self?.sendAddConnectionMessage()
        }
        self.setupEventHandler()
        let queue = DispatchQueue.main
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: 2.0)
        timer?.setEventHandler { [weak self] in
            self?.executeTask()
        }
        timer?.resume()
    }
    
    private func stopDebugReport() {
        timer?.cancel()
        timer = nil
        sendDebugReportStopMessage(id: reportId)
    }
    
    // MARK: - Private Helper Methods
    private func sendDebugReportStartMessage(id: UUID) {
        let statsMessage = DebugReportStartMessage(reportID: id.uuidString.lowercased())
        if let message = statsMessage.encode() {
            enqueueMessage(message)
            Logger.log.stats(message: "WebRTCStatsReporter:: sendDebugReportStartMessage [\(id.uuidString.lowercased())] message [\(String(describing: message))]")
        } else {
            Logger.log.e(message: "WebRTCStatsReporter:: sendDebugReportStartMessage error")
        }
    }
    
    private func sendDebugReportStopMessage(id: UUID) {
        let statsMessage = DebugReportStopMessage(reportID: id.uuidString.lowercased())
        if let message = statsMessage.encode() {
            enqueueMessage(message)
            Logger.log.stats(message: "WebRTCStatsReporter:: sendDebugReportStopMessage [\(id.uuidString.lowercased())] message [\(message)]")
        } else {
            Logger.log.e(message: "WebRTCStatsReporter:: sendDebugReportStopMessage error")
        }
    }
    
    private func sendDebugReportDataMessage(id: UUID, data: [String: Any]) {
        // Skip sending messages if reporting is paused due to socket disconnection or call state
        if isReportingPaused {
            Logger.log.i(message: "WebRTCStatsReporter:: Skipping stats message while socket is disconnected or call is recovering")
            return
        }
        
        let statsMessage = DebugReportDataMessage(reportID: id.uuidString.lowercased(), reportData: data)
        if let message = statsMessage.encode() {
            enqueueMessage(message)
            Logger.log.stats(message: "WebRTCStatsReporter:: sendDebugReportDataMessage [\(id.uuidString.lowercased())] message [\(String(describing: message))]")
        } else {
            Logger.log.e(message: "WebRTCStatsReporter:: sendDebugReportDataMessage error")
        }
    }
    
    private func sendWebRTCStatsEvent(event: WebRTCStatsEvent, tag: WebRTCStatsTag, data: [String: Any]) {
        var reportData = [String: Any]()
        reportData["event"] = event.rawValue
        reportData["tag"] = tag.rawValue
        reportData["connectionId"] = self.peer?.callLegID ?? UUID.init().uuidString.lowercased()
        reportData["peerId"] = peerId?.uuidString.lowercased() ?? UUID.init().uuidString.lowercased()
        reportData["data"] = data
        self.sendDebugReportDataMessage(id: reportId, data: reportData)
    }
    
    private func sendAddConnectionMessage() {
        var data = [String : Any]()
        data["event"] = WebRTCStatsEvent.addConnection.rawValue
        data["tag"] = WebRTCStatsTag.peer.rawValue
        
        data["connectionId"] = self.peer?.callLegID ?? UUID.init().uuidString.lowercased()
        data["peerId"] = peerId?.uuidString.lowercased() ?? UUID.init().uuidString.lowercased()
        
        var debugData = [String: Any]()
        var options = [String: Any]()
        options["peerId"] = peerId?.uuidString.lowercased() ?? UUID.init().uuidString.lowercased()
        
        if let connection = peer?.connection {
            debugData["peerConfiguration"] = connection.configuration.telnyx_to_stats_dictionary()
        }
        
        debugData["options"] = options
        data["data"] = debugData
        self.sendDebugReportDataMessage(id: reportId, data: data)
    }
    
    /// Updates the reporting state based on socket connection and call state
    /// - Parameter shouldPause: Whether to pause reporting
    public func updateReportingState(shouldPause: Bool) {
        if isReportingPaused != shouldPause {
            isReportingPaused = shouldPause
            Logger.log.i(message: "WebRTCStatsReporter:: Stats reporting \(shouldPause ? "paused" : "resumed")")
        }
    }
    
    /// Updates the reporting state based on call state changes
    /// - Parameter callState: The current call state
    public func handleCallStateChange(callState: CallState) {
        switch callState {
        case .RECONNECTING, .DROPPED:
            updateReportingState(shouldPause: true)
            Logger.log.i(message: "WebRTCStatsReporter:: Pausing stats reporting due to call state: \(callState.value)")
        case .ACTIVE:
            updateReportingState(shouldPause: false)
            Logger.log.i(message: "WebRTCStatsReporter:: Resuming stats reporting due to call state: \(callState.value)")
        default:
            // Keep current state for other call states
            break
        }
    }
    
    // MARK: - Real-time Metrics Conversion
    
    /// Converts WebRTC statistics to real-time call quality metrics
    /// - Parameter statsData: Dictionary containing WebRTC statistics
    /// - Returns: CallQualityMetrics object with calculated metrics
    private func toRealTimeMetrics(inboundboundAudio: [[String: Any]], audio: [String: Any]) -> CallQualityMetrics {
        // Extract remote audio stats
        let remoteAudio = audio["audio"] as? [String: [[String: Any]]] ?? [:]
        let remoteInbound = remoteAudio["remoteInbound"] ?? []
        let remoteOutbound = remoteAudio["remoteOutbound"] ?? []
        let inbound = remoteAudio["inbound"] ?? []
        let outbound = remoteAudio["outbound"] ?? []
        let candidates = remoteAudio["candidates"] ?? []
        
        // Extract metrics from stats
        let jitter = (inbound.first?["jitter"] as? Double) ?? Double.infinity
        let rtt = candidates.first?["totalRoundTripTime"] as? Double ?? Double.infinity
        let packetsReceived = (inboundboundAudio.first?["packetsReceived"] as? Int) ?? -1
        let packetsLost = (inboundboundAudio.first?["packetsLost"] as? Int) ?? -1
        
        // Calculate MOS score
        let mos = MOSCalculator.calculateMOS(
            jitter: jitter * 1000, // Convert to ms
            rtt: rtt * 1000,       // Convert to ms
            packetsReceived: packetsReceived,
            packetsLost: packetsLost
        )

        // Determine call quality
        let quality = MOSCalculator.getQuality(mos: mos)
                
        // Create metrics object
        return CallQualityMetrics(
            jitter: jitter,
            rtt: rtt,
            mos: mos,
            quality: quality,
            inboundAudio: inbound.first,
            outboundAudio: outbound.first,
            remoteInboundAudio: remoteInbound.first,
            remoteOutboundAudio: remoteOutbound.first
        )
    }
    
    // MARK: - Task Execution
    private func executeTask() {
        guard let peer = peer else { return }
        guard let call = call else { return }

        
        // Check socket connection state
        if let socket = socket, !socket.isConnected {
            updateReportingState(shouldPause: true)
            Logger.log.i(message: "WebRTCStatsReporter:: Skipping stats collection while socket is disconnected")
            return
        }
        
        // Check call state
        switch call.callState {
        case .RECONNECTING, .DROPPED:
            updateReportingState(shouldPause: true)
            Logger.log.i(message: "WebRTCStatsReporter:: Skipping stats collection while call is in \(call.callState.value) state")
            return
        default:
            updateReportingState(shouldPause: false)
        }
        
        // If we reach here, we can collect and send stats
        Logger.log.i(message: "WebRTCStatsReporter:: Task executed at \(Date())")
        peer.connection?.statistics(completionHandler: { [weak self] reports in
            guard let self = self else { return }
            var statsEvent = [String: Any]()
            var audioInboundStats = [Any]()
            var remoteAudioInboundStats = [Any]()
            var audioOutboundStats = [Any]()
            var remoteAudioOutboundStats = [Any]()
            var connectionCandidates = [Any]()
            var statsData = [String: Any]()
            var statsObject = [String: Any]()
            Logger.log.i(message: "WebRTCStatsReporter:: Task executed at \(reports.statistics)")

            reports.statistics.forEach { report in
                var values = report.value.values
                values["type"] = report.value.type as NSObject
                values["id"] = report.value.id as NSObject
                values["timestamp"] = (report.value.timestamp_us / 1000.0) as NSObject

                switch report.value.type {
                case "inbound-rtp":
                    if let kind = values["kind"] as? String, kind == "audio" {
                        audioInboundStats.append(values)
                        statsObject[report.key] = values
                    }

                case "outbound-rtp":
                    if let kind = values["kind"] as? String, kind == "audio" {
                        audioOutboundStats.append(values)
                        statsObject[report.key] = values
                    }

                case "remote-inbound-rtp":
                    if let kind = values["kind"] as? String, kind == "audio" {
                        remoteAudioInboundStats.append(values)
                        statsObject[report.key] = values
                    }

                case "remote-outbound-rtp":
                    if let kind = values["kind"] as? String, kind == "audio" {
                        remoteAudioOutboundStats.append(values)
                        statsObject[report.key] = values
                    }

                case "candidate-pair":
                    Logger.log.i(message: "Default_Values : \(values)")
                    connectionCandidates.append(values)
                    statsObject[report.key] = values

                default:
                    statsObject[report.key] = values
                }
            }

            // Otbound Stats
            audioOutboundStats.enumerated().forEach { index, outboundStat in
                if let outboundDict = outboundStat as? [String: NSObject],
                   let mediaSourceId = outboundDict["mediaSourceId"] as? String,
                   let mediaSource = statsObject[mediaSourceId] as? [String: NSObject] {
                    var updatedStat = outboundDict
                    var updatedMediaSource = mediaSource
                    updatedMediaSource["id"] = mediaSourceId as NSObject
                    updatedStat["track"] = updatedMediaSource as NSObject
                    audioOutboundStats[index] = updatedStat as NSDictionary
                }
            }

            // Retrieve the T01 stats and selectedCandidatePairId from the statsObject
            if let t01Stats = statsObject["T01"] as? [String: NSObject],
               let selectedCandidatePairId = t01Stats["selectedCandidatePairId"] as? String {
                // Find the corresponding candidate pair based on the selectedCandidatePairId
                if let connectionCandidateMap = connectionCandidates.first(where: { candidate in
                    if let candidateDict = candidate as? [String: NSObject],
                       let id = candidateDict["id"] as? String {
                        // Match the candidate id with the selectedCandidatePairId
                        return id == selectedCandidatePairId
                    }
                    return false
                }) as? [String: NSObject] {
                    var updatedConnection = connectionCandidateMap
                    
                    // Search for local and remote candidates using their respective ids
                    if let localId = connectionCandidateMap["localCandidateId"] as? String,
                       let local = statsObject[localId] as? [String: NSObject] {
                        // Update the local candidate data
                        var updatedLocal = local
                        updatedLocal["id"] = localId as NSObject
                        updatedConnection["local"] = updatedLocal as NSObject
                    }
                    
                    if let remoteId = connectionCandidateMap["remoteCandidateId"] as? String,
                       let remote = statsObject[remoteId] as? [String: NSObject] {
                        // Update the remote candidate data
                        var updatedRemote = remote
                        updatedRemote["id"] = remoteId as NSObject
                        updatedConnection["remote"] = updatedRemote as NSObject
                    }
                    // Add the updated connection candidate to the stats data
                    statsData["connection"] = updatedConnection
                }
            }

            // Event Object
            statsEvent["event"] = WebRTCStatsEvent.stats.rawValue as NSObject
            statsEvent["tag"] = WebRTCStatsTag.stats.rawValue as NSObject
            statsEvent["peerId"] = self.peerId?.uuidString as NSObject? ?? NSNull()
            statsEvent["connectionId"] = peer.callLegID as NSObject? ?? NSNull()
            
            statsData["audio"] = [
                "inbound": audioInboundStats,
                "outbound": audioOutboundStats
            ] as NSObject
            
            // Create remote data structure for metrics calculation
            let remoteData: [String: Any] = [
                "audio": [
                    "inbound": audioInboundStats,
                    "outbound": audioOutboundStats,
                    "remoteInbound": remoteAudioInboundStats,
                    "remoteOutbound": remoteAudioOutboundStats,
                    "candidates":connectionCandidates
                ]
            ]
            
            if !audioInboundStats.isEmpty {
                // Convert stats to typed arrays for metrics calculation
                let typedAudioInboundStats = audioInboundStats.compactMap { $0 as? [String: Any] }
                
                // Calculate real-time metrics
                let metrics = self.toRealTimeMetrics(inboundboundAudio: typedAudioInboundStats, audio: remoteData)
                
                // Emit metrics through callback
                self.onStatsFrame?(metrics)
            }
            
            statsEvent["data"] = statsData as NSObject
            statsEvent["statsObject"] = statsObject as NSObject

            self.sendDebugReportDataMessage(id: self.reportId, data: statsEvent)
        })
    }
    
    // MARK: - Message Queue
    private func enqueueMessage(_ message: String) {
        messageQueue.async { [weak self] in
            guard let self = self, !self.isReportingPaused else {
                Logger.log.i(message: "WebRTCStatsReporter:: Message sending skipped due to paused state")
                return
            }
            self.socket?.sendMessage(message: message)
        }
    }
}

// MARK: - Dispose
extension WebRTCStatsReporter {
    public func dispose() {
        self.stopDebugReport()
        timer?.cancel()
        timer = nil
        
        // Reset the reporting state
        isReportingPaused = false
        
        // Clear callbacks
        onStatsFrame = nil
        
        peerId = nil
        peer = nil
        socket = nil
        Logger.log.i(message: "WebRTCStatsReporter:: Disposed and resources cleared")
    }
}

// MARK: - Peer Event Handling
extension WebRTCStatsReporter {
    /// Sets up handlers for various WebRTC events to collect debugging information.
    /// This method configures callbacks for:
    /// - Media stream and track events
    /// - ICE candidate gathering and selection
    /// - Signaling state changes
    /// - Connection state changes
    /// - ICE gathering state changes
    /// - Negotiation events
    ///
    /// Each event handler collects relevant data and sends it to Telnyx's servers
    /// for analysis and debugging purposes.
    public func setupEventHandler() {
        // Handle new media streams being added to the connection
        self.peer?.onAddStream = { [weak self] stream in
            guard let self = self else { return }
            var debugData = [String: Any]()
            debugData["stream"] = stream.telnyx_to_stats_dictionary()
            if let track = stream.audioTracks.first {
                debugData["track"] = track.telnyx_to_stats_dictionary()
                debugData["title"] = track.kind + ":" + track.trackId + " stream:" + stream.streamId
            }
            self.sendWebRTCStatsEvent(event: .onTrack, tag: .track, data: debugData)
        }
        
        // Handle new ICE candidates being discovered
        self.peer?.onIceCandidate = { [weak self] candidate in
            guard let self = self else { return }
            var debugCandidate = [String: Any]()
            debugCandidate["candidate"] = candidate.sdp
            debugCandidate["sdpMLineIndex"] = candidate.sdpMLineIndex
            debugCandidate["sdpMid"] = candidate.sdpMid
            debugCandidate["usernameFragment"] = candidate.telnyx_stats_extractUfrag()
            self.sendWebRTCStatsEvent(event: .onIceCandidate, tag: .connection, data: debugCandidate)
        }
        
        // Handle changes in the WebRTC signaling state
        self.peer?.onSignalingStateChange = { [weak self] state, connection in
            guard let self = self else { return }
            var debugData = [String: Any]()
            debugData["signalingState"] = state.telnyx_to_string()
            debugData["localDescription"] = connection.localDescription?.sdp ?? ""
            debugData["remoteDescription"] = connection.remoteDescription?.sdp ?? ""
            self.sendWebRTCStatsEvent(event: .onSignalingStateChange, tag: .connection, data: debugData)
        }
        
        // Handle changes in the ICE connection state
        self.peer?.onIceConnectionChange = { [weak self] state in
            guard let self = self else { return }
            self.sendWebRTCStatsEvent(event: .onIceConnectionStateChange, tag: .connection, data: ["data": state.telnyx_to_string()])
        }
        
        // Handle changes in the ICE gathering state
        self.peer?.onIceGatheringChange = { [weak self] state in
            guard let self = self else { return }
            self.sendWebRTCStatsEvent(event: .onIceGatheringStateChange, tag: .connection, data: ["data": state.telnyx_to_string()])
        }
        
        // Handle WebRTC negotiation needed events
        self.peer?.onNegotiationNeeded = { [weak self] in
            guard let self = self else { return }
            self.sendWebRTCStatsEvent(event: .onNegotiationNeeded, tag: .connection, data: [:])
        }
    }
}
