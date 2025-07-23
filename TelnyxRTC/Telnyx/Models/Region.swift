//
//  Params.swift
//  TelnyxRTC
//
//  Created by Isaac Akakpo on 19/10/2023.
//

import Foundation

/// Enum representing the available regions for Telnyx WebRTC connections.
public enum Region: String,Codable, CaseIterable {
    case auto = "auto"
    case eu = "eu1"
    case usCentral = "us-central"
    case usEast = "us-east"
    case usWest = "us-west"
    case caCentral = "ca-central"
    case apac = "apac"
    
    var displayName: String {
        switch self {
        case .auto: return "AUTO"
        case .eu: return "EU"
        case .usCentral: return "US-CENTRAL"
        case .usEast: return "US-EAST"
        case .usWest: return "US-WEST"
        case .caCentral: return "CA-CENTRAL"
        case .apac: return "APAC"
        }
    }
    
    static func fromDisplayName(_ displayName: String) -> Region? {
        return Region.allCases.first { $0.displayName == displayName.uppercased() }
    }
    
    static func fromValue(_ value: String) -> Region? {
        return Region(rawValue: value)
    }
}
