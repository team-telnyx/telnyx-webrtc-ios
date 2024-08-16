//
//  StatsMessage.swift
//  TelnyxRTC
//
//  Created by Isaac Akakpo on 8/16/24.
//

import Foundation

private let PROTOCOL_VERSION: String = "2.0"

public class StatsMessage  {
    
    private var jsonMessage: [String: Any] = [String: Any]()
    let jsonrpc = PROTOCOL_VERSION
    var id: String = UUID.init().uuidString.lowercased()

    
    init(reportID:String,reportData:[String:Any]) {
        self.jsonMessage = [String: Any]()
        self.jsonMessage["jsonrpc"] = self.jsonrpc
        self.jsonMessage["id"] = self.id
        self.jsonMessage["debug_report_version"] = 1
        self.jsonMessage["debug_report_data"] = reportData
        self.jsonMessage["type"] = "debug_report_data"
        self.jsonMessage["debug_report_id"] = reportID
    }
    
    func encode() -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonMessage, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            Logger.log.e(message: "Message:: encode() error")
            return nil
        }
        Logger.log.i(message: "Message:: encode() " + jsonString)
        return jsonString
    }
    
    
}
