import WebRTC

class WebRTCStatsReporter {
    // MARK: - Properties
    private let CANDIDATE_PAIR_LIMIT = 5
    public var debug: Bool = false
    private var timer: DispatchSourceTimer?
    private var debugStatsId: UUID = UUID()
    private var debugReportStarted: Bool = false
    private var peerId: UUID?
    private weak var peer: Peer?
    weak var socket: Socket?
    
    // MARK: - Initializer
    init(peer: Peer, socket: Socket) {
        self.peer = peer
        self.socket = socket
        self.setupEventHandler()
    }
    
    // MARK: - Start/Stop Reporting
    public func startDebugReport(peer: Peer, peerId: UUID) {
        guard !debug else { return }
        self.peer = peer
        self.peerId = peerId
        self.debug = true
        let queue = DispatchQueue.main
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: 2.0)
        timer?.setEventHandler { [weak self] in
            self?.executeTask()
        }
        timer?.resume()
    }
    
    public func stopDebugReport() {
        guard debug else { return }
        debug = false
        timer?.cancel()
        timer = nil
        if debugReportStarted {
            sendDebugReportStopMessage(id: debugStatsId)
        }
        debugReportStarted = false
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
        
        if !debugReportStarted {
            debugStatsId = UUID()
            sendDebugReportStartMessage(id: debugStatsId)
            debugReportStarted = true
        }
        
        var statsEvent = [String: Any]()
        var inboundStats = [Any]()
        var outBoundStats = [Any]()
        var statsData = [String: Any]()
        var audio = [String: [Any]]()
        var candidatePairs = [Any]()
        
        statsEvent["event"] = "stats"
        statsEvent["tag"] = "stats"
        statsEvent["peerId"] = peerId?.uuidString
        statsEvent["connectionId"] = peer.callLegID ?? ""
        
        peer.connection?.statistics(completionHandler: { reports in
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
        })
        
        audio["outbound"] = outBoundStats
        audio["inbound"] = inboundStats
        statsData["audio"] = audio
        statsEvent["data"] = statsData
        
        if !inboundStats.isEmpty && !outBoundStats.isEmpty && !candidatePairs.isEmpty {
            inboundStats.removeAll()
            outBoundStats.removeAll()
            candidatePairs.removeAll()
            statsData.removeAll()
            audio.removeAll()
            sendDebugReportDataMessage(id: debugStatsId, data: statsEvent)
        }
    }
}

// MARK: - Dispose
extension WebRTCStatsReporter {
    public func dispose() {
        timer?.cancel()
        timer = nil

        debug = false
        debugReportStarted = false
        
        peerId = nil
        peer = nil
        socket = nil
        
        Logger.log.i(message: "WebRTCStatsReporter:: Disposed and resources cleared")
    }
}

// MARK: - Peer Event Handling
extension WebRTCStatsReporter {
    public func setupEventHandler() {
        self.peer?.onSignalingStateChange = { [weak self] state in
            print("Signaling state changed: \(state)")
        }
        
        self.peer?.onAddStream = { [weak self] stream in
            print("Stream added: \(stream)")
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
        
        self.peer?.onIceCandidate = { [weak self] candidate in
            print("New ICE candidate: \(candidate)")
        }
        
        self.peer?.onRemoveIceCandidates = { [weak self] candidates in
            print("ICE candidates removed: \(candidates)")
        }
        
        self.peer?.onDataChannel = { [weak self] channel in
            print("Data channel opened: \(channel)")
        }
    }
}

