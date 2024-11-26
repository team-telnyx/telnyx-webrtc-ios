//
//  StatsMessage.swift
//  TelnyxRTC
//
//  Created by Isaac Akakpo on 8/16/24.
//

import Foundation

private let DEBUG_REPORT_VERSION: Int = 1

enum StatsMessageType : String  {
    case DEBUG_REPORT_STOP = "debug_report_stop"
    case DEBUG_REPORT_START = "debug_report_start"
    case DEBUG_REPORT_DATA = "debug_report_data"
}

class StatsMessage: Message  {
    init(type: StatsMessageType,
         reportID: String,
         reportData: [String:Any]?) {
        super.init()
        self.jsonMessage["debug_report_version"] = DEBUG_REPORT_VERSION
        self.jsonMessage["debug_report_data"] = reportData
        self.jsonMessage["type"] = type.rawValue
        self.jsonMessage["debug_report_id"] = reportID
    }
}
