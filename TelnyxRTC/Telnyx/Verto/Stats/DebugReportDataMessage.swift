
class DebugReportDataMessage: StatsMessage  {
    init(reportID: String, reportData: [String: Any]) {
        super.init(type: .DEBUG_REPORT_DATA,
                   reportID: reportID,
                   reportData: reportData)
    }
}
