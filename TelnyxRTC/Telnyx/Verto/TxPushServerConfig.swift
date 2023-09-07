//
//  PushConfig.swift
//  TelnyxRTC
//
//  Created by Isaac Akakpo on 07/09/2023.
//

import Foundation

/// This class contains all the properties related to Server Confuguration from Push
public struct TxPushServerConfig {
    

    public internal(set) var rtc_ip:String
    public internal(set) var rtc_port:String
    
    public init(rtc_ip: String, rtc_port: String) {
        self.rtc_ip = rtc_ip
        self.rtc_port = rtc_port
    }
    
}
