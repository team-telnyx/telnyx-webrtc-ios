//
//  SSLValidationHelper.swift
//  TelnyxRTC
//
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import Foundation
import Darwin

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

        if isPrivateOrLoopbackIPv4(host) {
            return true
        }

        if isPrivateOrLoopbackIPv6(host) {
            return true
        }

        return false
    }

    private static func isPrivateOrLoopbackIPv4(_ host: String) -> Bool {
        // Strip IPv4-in-IPv6 wrapper if present (e.g. ::ffff:127.0.0.1)
        let ipv4Part = host.hasPrefix("::ffff:") ? String(host.dropFirst(7)) : host

        let octets = ipv4Part.split(separator: ".", omittingEmptySubsequences: false)
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

    private static func isPrivateOrLoopbackIPv6(_ host: String) -> Bool {
        // First validate this is actually an IPv6 literal
        var addr = in6_addr()
        guard inet_pton(AF_INET6, host, &addr) == 1 else { return false }

        // Now safe to do prefix checks — host is confirmed IPv6
        if host == "::1" { return true }

        // fc00::/7 → unique-local (fc00:: – fdff::)
        if host.hasPrefix("fc") || host.hasPrefix("fd") { return true }

        // fe80::/10 → link-local
        if host.hasPrefix("fe80") { return true }

        return false
    }
}
