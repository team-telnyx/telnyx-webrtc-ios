//
//  RtcCustomHeaders.swift
//  TelnyxRTC
//
//  Created by Isaac Akakpo on 17/10/2023.
//

import Foundation

struct RtcCustomHeader {
    public internal(set) var key: String
    public internal(set) var value: String
    public init(key:String,value:String){
        self.key = key
        self.value = value
    }
}
