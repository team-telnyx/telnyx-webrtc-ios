// MARK: - Peer + Stats
extension Peer {

    func startDebugReportTimer(peerId: UUID) {
        self.peerId = peerId
        self.isDebugStats = true
        let queue = DispatchQueue.main
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: 2.0)
        timer?.setEventHandler { [weak self] in
            self?.executeTask()
        }
        timer?.resume()
    }
    
    func stopDebugReportTimer() {
        timer?.cancel()
        timer = nil
        sendDebugReportStopMessage(id: debugStatsId)
        debugReportStarted = false
        isDebugStats = false
    }

    fileprivate func sendDebugReportStartMessage(id: UUID) {
        let statsMessage = DebugReportStartMessage(reportID: id.uuidString.lowercased())
        if let message = statsMessage.encode(),
           let socket = self.socket {
            socket.sendMessage(message: message)
            Logger.log.stats(message: "Peer+Stats:: sendDebugReportStartMessage [\(id.uuidString.lowercased())] message [\(String(describing: message))]")
        } else {
            Logger.log.e(message: "Peer+Stats:: sendDebugReportStartMessage error")
        }
    }
    
    fileprivate func sendDebugReportStopMessage(id: UUID) {
        let statsMessage = DebugReportStopMessage(reportID: id.uuidString.lowercased())
        if let message = statsMessage.encode(),
           let socket = self.socket {
            socket.sendMessage(message: message)
            Logger.log.stats(message: "Peer+Stats:: sendDebugReportStopMessage [\(id.uuidString.lowercased())] message [\(message)]")
        } else {
            Logger.log.e(message: "Peer+Stats:: sendDebugReportStopMessage error")
        }
    }
    
    func sendDebugReportDataMessage(id: UUID, data: [String: Any]) {
        let statsMessage = DebugReportDataMessage(reportID: id.uuidString.lowercased(),
                                                  reportData: data)
        if let message = statsMessage.encode(),
           let socket = self.socket {
            socket.sendMessage(message: message)
            Logger.log.stats(message: "Peer+Stats:: sendDebugReportDataMessage [\(id.uuidString.lowercased())] message [\(String(describing: message))]")
        } else {
            Logger.log.e(message: "Peer+Stats:: sendDebugReportDataMessage error")
        }
    }

    private func executeTask() {
        Logger.log.i(message: "Peer+Stats:: Task executed at \(Date())")
        if !debugReportStarted {
            debugStatsId = UUID.init()
            sendDebugReportStartMessage(id: debugStatsId)
            debugReportStarted = true
        }
        
        var statsEvent = [String: Any]()
        var inboundStats = [Any]()
        var outBoundStats = [Any]()
        var statsData = [String: Any]()
        var audio = [String: [Any]]()
        var candidatePairs =  [Any]()

        statsEvent["event"] = "stats"
        statsEvent["tag"] = "stats"
        statsEvent["peerId"] = peerId.uuidString
        statsEvent["connectionId"] = callLegID ?? ""
        
        self.connection?.statistics(completionHandler: { reports in
            reports.statistics.forEach { report in
                if(report.value.type == "inbound-rtp") {
                    //Logger.log.i(message: "Peer:: ICE negotiation updated. Report New: \(report.values)")
                    inboundStats.append(report.value.values)
                }
                if(report.value.type == "outbound-rtp") {
                    //Logger.log.i(message: "Peer:: ICE negotiation updated. Report New: \(report.values)")
                    outBoundStats.append(report.value.values)
                }
                if(report.value.type == "candidate-pair" && candidatePairs.count < self.CANDIDATE_PAIR_LIMIT) {
                    //Logger.log.i(message: "Peer:: ICE negotiation updated. Report New: \(report.values)")
                    candidatePairs.append(report.value.values)
                }
            }
        })
        audio["outbound"] = outBoundStats
        audio["inbound"] = inboundStats
        statsData["audio"] = audio
        statsEvent["data"] = statsData
        
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
