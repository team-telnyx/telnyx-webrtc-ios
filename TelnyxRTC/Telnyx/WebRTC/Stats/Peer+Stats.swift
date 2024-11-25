extension Peer {

    public func startTimer() {
        isDebugStats = true
        let queue = DispatchQueue.main
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: 2.0)
        timer?.setEventHandler { [weak self] in
            self?.executeTask()
        }
        timer?.resume()
    }
    
    public func stopTimer() {
        statsData["audio"] = audio
        statsEvent["data"] = statsData
        statsEvent.printJson()
        timer?.cancel()
        timer = nil
        sendStatsType(id: debugStatsId, type: StatsType.STOP_STARTS.rawValue)
        debugReportStarted = false
        isDebugStats = false
    }
    
    fileprivate func sendStats(id:UUID, data:[String:Any]) {
        Logger.log.e(message: "TxClient:: Sending Stats")
        let statsMessage = StatsMessage(reportID: id.uuidString.lowercased(), reportData: data)
        self.socket?.sendMessage(message: statsMessage.encode())
    }
    
    fileprivate func sendStatsType(id:UUID, type:String) {
        Logger.log.e(message: "TxClient:: Sending Stats \(type)")
        let statsMessage = InitiateOrStopStats(type: type, reportID: id.uuidString.lowercased())
        self.socket?.sendMessage(message: statsMessage.encode())
    }
    
    
    private func executeTask() {
        print("Task executed at \(Date())")
        
        if !debugReportStarted {
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
}


// MARK: - Stats

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
