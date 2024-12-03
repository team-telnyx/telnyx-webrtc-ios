import WebRTC

class WebRTCStatsReporter {
    // MARK: - Properties
    private let CANDIDATE_PAIR_LIMIT = 5
    private var timer: DispatchSourceTimer?
    private var peerId: UUID?
    private var reportId: UUID = UUID.init()
    private weak var peer: Peer?
    weak var socket: Socket?
    private let messageQueue = DispatchQueue(label: "WebRTCStatsReporter.MessageQueue") // Serial queue
    
    // MARK: - Initializer
    init(peerId: UUID, peer: Peer, socket: Socket) {
        self.peerId = peerId
        self.peer = peer
        self.socket = socket
        self.initializeReporter()
        self.setupEventHandler()
    }
    
    // MARK: - Private Initialization Method
    private func initializeReporter() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            self.sendDebugReportStartMessage(id: self.reportId)
            self.sendAddConnectionMessage()
            DispatchQueue.main.async { [weak self] in
                self?.startDebugReport()
            }
        }
    }
    
    // MARK: - Start/Stop Reporting
    public func startDebugReport() {
        let queue = DispatchQueue.main
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: 2.0)
        timer?.setEventHandler { [weak self] in
            self?.executeTask()
        }
        timer?.resume()
    }
    
    public func stopDebugReport() {
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
        let statsMessage = DebugReportDataMessage(reportID: id.uuidString.lowercased(), reportData: data)
        if let message = statsMessage.encode() {
            enqueueMessage(message)
            Logger.log.stats(message: "WebRTCStatsReporter:: sendDebugReportDataMessage [\(id.uuidString.lowercased())] message [\(String(describing: message))]")
        } else {
            Logger.log.e(message: "WebRTCStatsReporter:: sendDebugReportDataMessage error")
        }
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
            var peerConfiguration = [String: Any]()
            peerConfiguration["bundlePolicy"] = connection.configuration.bundlePolicy.telnyx_to_string()
            peerConfiguration["iceTransportPolicy"] = connection.configuration.iceTransportPolicy.telnyx_to_string()
            peerConfiguration["rtcpMuxPolicy"] = connection.configuration.rtcpMuxPolicy.telnyx_to_string()
            peerConfiguration["continualGatheringPolicy"] = connection.configuration.continualGatheringPolicy.telnyx_to_string()
            peerConfiguration["sdpSemantics"] = connection.configuration.sdpSemantics.telnyx_to_string()
            peerConfiguration["iceCandidatePoolSize"] = connection.configuration.iceCandidatePoolSize
            peerConfiguration["iceServers"] = connection.configuration.iceServers.map { $0.telnyx_to_stats_dictionary() }
            peerConfiguration["rtcpAudioReportIntervalMs"] = connection.configuration.rtcpAudioReportIntervalMs
            peerConfiguration["rtcpVideoReportIntervalMs"] = connection.configuration.rtcpVideoReportIntervalMs
            
            debugData["peerConfiguration"] = peerConfiguration
        }
        
        debugData["options"] = options
        data["data"] = debugData
        self.sendDebugReportDataMessage(id: reportId, data: data)
    }
    
    // MARK: - Task Execution
    private func executeTask() {
        guard let peer = peer else { return }
        Logger.log.i(message: "WebRTCStatsReporter:: Task executed at \(Date())")
        peer.connection?.statistics(completionHandler: { [weak self] reports in
            guard let self = self else { return }
            var statsEvent = [String: Any]()
            var audioInboundStats = [Any]()
            var audioOutboundStats = [Any]()
            var connection = [Any]()
            var statsData = [String: Any]()
            var statsObject = [String: Any]()
            
            reports.statistics.forEach { report in
                let values = report.value.values
                switch report.value.type {
                    case "inbound-rtp":
                        audioInboundStats.append(values)
                        
                    case "outbound-rtp":
                        audioOutboundStats.append(values)
                        
                    case "candidate-pair":
                        connection.append(values)
                    default:
                        statsObject[report.key] = values
                }
            }
            
            statsEvent["event"] = WebRTCStatsEvent.stats.rawValue
            statsEvent["tag"] = WebRTCStatsTag.stats.rawValue
            statsEvent["peerId"] = self.peerId?.uuidString
            statsEvent["connectionId"] = peer.callLegID ?? ""
            
            statsData["audio"] = [
                "inbound": audioInboundStats,
                "outbound": audioOutboundStats
            ]
            statsData["connection"] = connection
            statsEvent["data"] = statsData
            statsEvent["statsObject"] = statsObject
            self.sendDebugReportDataMessage(id: self.reportId, data: statsEvent)
        })
    }
    
    // MARK: - Message Queue
    private func enqueueMessage(_ message: String) {
        messageQueue.async { [weak self] in
            self?.socket?.sendMessage(message: message)
        }
    }
}

// MARK: - Dispose
extension WebRTCStatsReporter {
    public func dispose() {
        self.stopDebugReport()
        timer?.cancel()
        timer = nil
        
        peerId = nil
        peer = nil
        socket = nil
        Logger.log.i(message: "WebRTCStatsReporter:: Disposed and resources cleared")
    }
}

// MARK: - Peer Event Handling
extension WebRTCStatsReporter {
    public func setupEventHandler() {
        self.peer?.onAddStream = { [weak self] stream in
            guard let self = self else { return }
            var data = [String : Any]()
            data["event"] = WebRTCStatsEvent.onTrack.rawValue
            data["tag"] = WebRTCStatsTag.track.rawValue
            
            // TODO: CHECK CONNECTION ID
            data["connectionId"] = self.peer?.callLegID ??  UUID.init().uuidString.lowercased()
            data["peerId"] = peerId?.uuidString.lowercased() ?? UUID.init().uuidString.lowercased()
            
            var debugData = [String: Any]()
            debugData["stream"] = stream.telnyx_to_stats_dictionary()
            if let track = stream.audioTracks.first {
                debugData["track"] = track.telnyx_to_stats_dictionary()
                debugData["title"] = track.kind + ":" + track.trackId + " stream:" + stream.streamId
            }
            data["data"] = debugData
            self.sendDebugReportDataMessage(id: reportId, data: data)
        }
        
        self.peer?.onIceCandidate = { [weak self] candidate in
            guard let self = self else { return }
            
            var data = [String : Any]()
            data["event"] = WebRTCStatsEvent.onIceCandidate.rawValue
            data["tag"] = WebRTCStatsTag.connection.rawValue
            
            // TODO: CHECK CONNECTION ID
            data["connectionId"] = self.peer?.callLegID ??  UUID.init().uuidString.lowercased()
            data["peerId"] = peerId?.uuidString.lowercased() ?? UUID.init().uuidString.lowercased()
            
            var debugCandidate = [String: Any]()
            debugCandidate["candidate"] = candidate.sdp
            debugCandidate["sdpMLineIndex"] = candidate.sdpMLineIndex
            debugCandidate["sdpMid"] = candidate.sdpMid
            debugCandidate["usernameFragment"] = candidate.telnyx_stats_extractUfrag()
            
            data["data"] = debugCandidate
            self.sendDebugReportDataMessage(id: reportId, data: data)
        }
        
        self.peer?.onSignalingStateChange = { [weak self] state, connection in
            guard let self = self else { return }
            
            var data = [String : Any]()
            data["event"] = WebRTCStatsEvent.onSignalingStateChange.rawValue
            data["tag"] = WebRTCStatsTag.connection.rawValue
            
            // TODO: CHECK CONNECTION ID
            data["connectionId"] = self.peer?.callLegID ??  UUID.init().uuidString.lowercased()
            data["peerId"] = peerId?.uuidString.lowercased() ?? UUID.init().uuidString.lowercased()
            
            var debugData = [String: Any]()
            debugData["signalingState"] = state.telnyx_to_string()
            debugData["localDescription"] = connection.localDescription?.sdp ?? ""
            debugData["remoteDescription"] = connection.remoteDescription?.sdp ?? ""
            
            data["data"] = debugData
            self.sendDebugReportDataMessage(id: reportId, data: data)
        }
        
        self.peer?.onIceConnectionChange = { [weak self] state in
            guard let self = self else { return }
            
            var data = [String : Any]()
            data["event"] = WebRTCStatsEvent.onIceConnectionStateChange.rawValue
            data["tag"] = WebRTCStatsTag.connection.rawValue
            
            // TODO: CHECK CONNECTION ID
            data["connectionId"] = self.peer?.callLegID ??  UUID.init().uuidString.lowercased()
            data["peerId"] = peerId?.uuidString.lowercased() ?? UUID.init().uuidString.lowercased()
            data["data"] = state.telnyx_to_string()
            self.sendDebugReportDataMessage(id: reportId, data: data)
        }
        
        self.peer?.onIceGatheringChange = { [weak self] state in
            guard let self = self else { return }
            
            var data = [String : Any]()
            data["event"] = WebRTCStatsEvent.onIceGatheringStateChange.rawValue
            data["tag"] = WebRTCStatsTag.connection.rawValue
            
            // TODO: CHECK CONNECTION ID
            data["connectionId"] = self.peer?.callLegID ??  UUID.init().uuidString.lowercased()
            data["peerId"] = peerId?.uuidString.lowercased() ?? UUID.init().uuidString.lowercased()
            data["data"] = state.telnyx_to_string()
            self.sendDebugReportDataMessage(id: reportId, data: data)
        }
        
        self.peer?.onNegotiationNeeded = { [weak self] in
            guard let self = self else { return }
            
            var data = [String : Any]()
            data["event"] = WebRTCStatsEvent.onNegotiationNeeded.rawValue
            data["tag"] = WebRTCStatsTag.connection.rawValue
            
            // TODO: CHECK CONNECTION ID
            data["connectionId"] = self.peer?.callLegID ??  UUID.init().uuidString.lowercased()
            data["peerId"] = peerId?.uuidString.lowercased() ?? UUID.init().uuidString.lowercased()
            self.sendDebugReportDataMessage(id: reportId, data: data)
        }
    }
}
