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
            var debugData = [String: Any]()
            debugData["stream"] = stream.telnyx_to_stats_dictionary()
            if let track = stream.audioTracks.first {
                debugData["track"] = track.telnyx_to_stats_dictionary()
                debugData["title"] = track.kind + ":" + track.trackId + " stream:" + stream.streamId
            }
            self.sendWebRTCStatsEvent(event: .onTrack, tag: .track, data: debugData)
        }
        
        self.peer?.onIceCandidate = { [weak self] candidate in
            guard let self = self else { return }
            var debugCandidate = [String: Any]()
            debugCandidate["candidate"] = candidate.sdp
            debugCandidate["sdpMLineIndex"] = candidate.sdpMLineIndex
            debugCandidate["sdpMid"] = candidate.sdpMid
            debugCandidate["usernameFragment"] = candidate.telnyx_stats_extractUfrag()
            self.sendWebRTCStatsEvent(event: .onIceCandidate, tag: .connection, data: debugCandidate)
        }
        
        self.peer?.onSignalingStateChange = { [weak self] state, connection in
            guard let self = self else { return }
            var debugData = [String: Any]()
            debugData["signalingState"] = state.telnyx_to_string()
            debugData["localDescription"] = connection.localDescription?.sdp ?? ""
            debugData["remoteDescription"] = connection.remoteDescription?.sdp ?? ""
            self.sendWebRTCStatsEvent(event: .onSignalingStateChange, tag: .connection, data: debugData)
        }
        
        self.peer?.onIceConnectionChange = { [weak self] state in
            guard let self = self else { return }
            self.sendWebRTCStatsEvent(event: .onIceConnectionStateChange, tag: .connection, data: ["data": state.telnyx_to_string()])
        }
        
        self.peer?.onIceGatheringChange = { [weak self] state in
            guard let self = self else { return }
            self.sendWebRTCStatsEvent(event: .onIceGatheringStateChange, tag: .connection, data: ["data": state.telnyx_to_string()])
        }
        
        self.peer?.onNegotiationNeeded = { [weak self] in
            guard let self = self else { return }
            self.sendWebRTCStatsEvent(event: .onNegotiationNeeded, tag: .connection, data: [:])
        }
    }
}
