
import Foundation

class DebugReportStopMessage: StatsMessage  {
    init(reportID: String) {
        super.init(type: .DEBUG_REPORT_STOP,
                   reportID: reportID,
                   reportData: nil)
    }
}
