//
//  TxClient.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 01/03/2021.
//

import Foundation

public class TxClient {
    
    private let CURRENT_VERSION = "1.0.0"
    
    public init() {}
    
    public func getVersion() -> String {
        return CURRENT_VERSION
    }
}
