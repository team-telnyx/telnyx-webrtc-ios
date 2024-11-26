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
    
    internal func stopTimer() {
        statsData["audio"] = audio
        statsEvent["data"] = statsData
        statsEvent.printJson()
        timer?.cancel()
        timer = nil
        sendDebugReportStopMessage(id: debugStatsId)
        debugReportStarted = false
        isDebugStats = false
    }

    fileprivate func sendDebugReportStartMessage(id: UUID) {
        Logger.log.stats(message: "TxClient:: sendDebugReportStartMessage [\(id.uuidString.lowercased())]")
        let statsMessage = DebugReportStartMessage(reportID: id.uuidString.lowercased())
        self.socket?.sendMessage(message: statsMessage.encode())
    }
    
    fileprivate func sendDebugReportStopMessage(id: UUID) {
        Logger.log.stats(message: "TxClient:: sendDebugReportStopMessage [\(id.uuidString.lowercased())]")
        let statsMessage = DebugReportStopMessage(reportID: id.uuidString.lowercased())
        self.socket?.sendMessage(message: statsMessage.encode())
    }
    
    fileprivate func sendDebugReportDataMessage(id: UUID, data: [String: Any]) {
        Logger.log.stats(message: "TxClient:: sendDebugReportDataMessage \(id.uuidString.lowercased())")
        let statsMessage = DebugReportDataMessage(reportID: id.uuidString.lowercased(),
                                                  reportData: data)
        self.socket?.sendMessage(message: statsMessage.encode())
    }

    private func executeTask() {
        print("Task executed at \(Date())")
        
        if !debugReportStarted {
            debugStatsId = UUID.init()
            sendDebugReportStartMessage(id: debugStatsId)
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
        
        if(inboundStats.count > 0 && outBoundStats.count > 0 && candidatePairs.count > 0) {
            inboundStats.removeAll()
            outBoundStats.removeAll()
            candidatePairs.removeAll()
            statsData.removeAll()
            audio.removeAll()
            self.sendDebugReportDataMessage(id: debugStatsId, data: statsEvent)
        }
    }
}
