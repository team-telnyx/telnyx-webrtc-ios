import Foundation

class DebugReportStartMessage: StatsMessage  {
    init(reportID: String) {
        super.init(type: .DEBUG_REPORT_START,
                   reportID: reportID,
                   reportData: nil)
    }
}
