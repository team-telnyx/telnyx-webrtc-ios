import WebRTC

class WebRTCStatsReporter {
    // MARK: - Properties
    private let CANDIDATE_PAIR_LIMIT = 5
    private var timer: DispatchSourceTimer?
    private var peerId: UUID?
    private var reportId: UUID = UUID.init()
    private weak var peer: Peer?
    weak var socket: Socket?
    
    // MARK: - Initializer
    init(peerId: UUID, peer: Peer, socket: Socket) {
        self.peerId = peerId
        self.peer = peer
        self.socket = socket
        self.setupEventHandler()
        self.sendDebugReportStartMessage(id: reportId)
        self.startDebugReport()
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
        if let message = statsMessage.encode(), let socket = self.socket {
            socket.sendMessage(message: message)
            Logger.log.stats(message: "WebRTCStatsReporter:: sendDebugReportStartMessage [\(id.uuidString.lowercased())] message [\(String(describing: message))]")
        } else {
            Logger.log.e(message: "WebRTCStatsReporter:: sendDebugReportStartMessage error")
        }
    }
    
    private func sendDebugReportStopMessage(id: UUID) {
        let statsMessage = DebugReportStopMessage(reportID: id.uuidString.lowercased())
        if let message = statsMessage.encode(), let socket = self.socket {
            socket.sendMessage(message: message)
            Logger.log.stats(message: "WebRTCStatsReporter:: sendDebugReportStopMessage [\(id.uuidString.lowercased())] message [\(message)]")
        } else {
            Logger.log.e(message: "WebRTCStatsReporter:: sendDebugReportStopMessage error")
        }
    }
    
    private func sendDebugReportDataMessage(id: UUID, data: [String: Any]) {
        let statsMessage = DebugReportDataMessage(reportID: id.uuidString.lowercased(), reportData: data)
        if let message = statsMessage.encode(), let socket = self.socket {
            socket.sendMessage(message: message)
            Logger.log.stats(message: "WebRTCStatsReporter:: sendDebugReportDataMessage [\(id.uuidString.lowercased())] message [\(String(describing: message))]")
        } else {
            Logger.log.e(message: "WebRTCStatsReporter:: sendDebugReportDataMessage error")
        }
    }
    
    // MARK: - Task Execution
    private func executeTask() {
        guard let peer = peer else { return }
        Logger.log.i(message: "WebRTCStatsReporter:: Task executed at \(Date())")
        peer.connection?.statistics(completionHandler: { [weak self] reports in
            guard let self = self else { return }
            var statsEvent = [String: Any]()
            var inboundStats = [Any]()
            var outBoundStats = [Any]()
            var statsData = [String: Any]()
            var audio = [String: [Any]]()
            var candidatePairs = [Any]()
            
            reports.statistics.forEach { report in
                if report.value.type == "inbound-rtp" {
                    inboundStats.append(report.value.values)
                }
                if report.value.type == "outbound-rtp" {
                    outBoundStats.append(report.value.values)
                }
                if report.value.type == "candidate-pair" && candidatePairs.count < self.CANDIDATE_PAIR_LIMIT {
                    candidatePairs.append(report.value.values)
                }
            }
        
            
            statsEvent["event"] = WebRTCStatsEvent.stats.rawValue
            statsEvent["tag"] = WebRTCStatsTag.stats.rawValue
            statsEvent["peerId"] = self.peerId?.uuidString
            statsEvent["connectionId"] = peer.callLegID ?? ""
            audio["outbound"] = outBoundStats
            audio["inbound"] = inboundStats
            statsData["audio"] = audio
            statsEvent["data"] = statsData
            self.sendDebugReportDataMessage(id: self.reportId, data: statsEvent)

            if !inboundStats.isEmpty && !outBoundStats.isEmpty && !candidatePairs.isEmpty {
                inboundStats.removeAll()
                outBoundStats.removeAll()
                candidatePairs.removeAll()
                statsData.removeAll()
                audio.removeAll()
            }
        })
    
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
            print("Stream added: \(stream)")
            guard let self = self else { return }
            var data = [String : Any]()
            data["event"] = WebRTCStatsEvent.onTrack.rawValue
            data["tag"] = WebRTCStatsTag.track.rawValue
            
            // TODO: CHECK CONNECTION ID
            data["connectionId"] = self.peer?.callLegID ??  UUID.init().uuidString.lowercased()
            data["peerId"] = peerId?.uuidString.lowercased() ?? UUID.init().uuidString.lowercased()
            
            var debugData = [String: Any]()
            debugData["stream"] = getStreamDetails(stream: stream)
            if let track = stream.audioTracks.first {
                debugData["track"] = getAudioTrackDetails(track: track)
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
            debugCandidate["usernameFragment"] = StatsUtils.extractUfrag(from: candidate.sdp) ?? ""
            
            data["data"] = debugCandidate
            self.sendDebugReportDataMessage(id: reportId, data: data)
        }
        
        self.peer?.onSignalingStateChange = { [weak self] state in
            guard let self = self else { return }
        }

        self.peer?.onRemoveStream = { [weak self] stream in
            print("Stream removed: \(stream)")
        }
        
        self.peer?.onNegotiationNeeded = { [weak self] in
            print("Negotiation needed.")
        }
        
        self.peer?.onIceConnectionChange = { [weak self] state in
            print("ICE connection state changed: \(state)")
        }
        
        self.peer?.onIceGatheringChange = { [weak self] state in
            print("ICE gathering state changed: \(state)")
        }
        
        self.peer?.onRemoveIceCandidates = { [weak self] candidates in
            print("ICE candidates removed: \(candidates)")
        }
        
        self.peer?.onDataChannel = { [weak self] channel in
            print("Data channel opened: \(channel)")
        }
    }
}



extension WebRTCStatsReporter {
    
    func getStreamDetails(stream: RTCMediaStream) -> [String: Any] {
        var data = [String : Any]()
        data["id"] = stream.streamId
        return data
    }
    
    func getAudioTrackDetails(track: RTCMediaStreamTrack) -> [String: Any] {
        var data = [String : Any]()
        data["enabled"] = track.isEnabled
        data["id"] = track.trackId
        data["kind"] = track.kind
        data["readyState"] = track.readyState
        return data
    }
}
