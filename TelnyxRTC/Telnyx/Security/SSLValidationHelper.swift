//
//  SSLValidationHelper.swift
//  TelnyxRTC
//
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import Foundation

enum SSLValidationHelper {

    static let localHosts: [String] = [
        "localhost",
        "127.0.0.1"
    ]

    static func shouldAllowSelfSigned(for url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }

        if localHosts.contains(host) {
            return true
        }

        if isPrivateOrLoopbackIP(host) {
            return true
        }

        return false
    }

    private static func isPrivateOrLoopbackIP(_ host: String) -> Bool {
        let octets = host.split(separator: ".", omittingEmptySubsequences: false)
        guard octets.count == 4 else { return false }

        var bytes: [UInt8] = []
        for octetStr in octets {
            guard let value = UInt8(octetStr) else { return false }
            bytes.append(value)
        }

        let first = bytes[0]
        let second = bytes[1]

        if first == 127 { return true }
        if first == 10 { return true }
        if first == 192 && second == 168 { return true }
        if first == 172 && (16...31).contains(second) { return true }

        return false
    }
}
