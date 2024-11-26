
class DebugReportDataMessage: StatsMessage  {
    init(reportID: String, reportData: [String: Any]) {
        
        var data = reportData
        data["timeTaken"] = 1
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = dateFormatter.string(from: Date())
        data["timestamp"] = timestamp
        super.init(type: .DEBUG_REPORT_DATA,
                   reportID: reportID,
                   reportData: data)
    }
}
