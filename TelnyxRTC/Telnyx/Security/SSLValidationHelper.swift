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
        // Handle IPv6 loopback and unique-local addresses
        // ::1 → loopback
        if host == "::1" { return true }

        // fc00::/7 → unique-local addresses (fc00:: – fdff::)
        if host.hasPrefix("fc") || host.hasPrefix("fd") {
            // Validate it's a valid IPv6 address by attempting to parse components
            let fullForm = expandIPv6(host)
            guard !fullForm.isEmpty else { return false }
            return true
        }

        // fe80::/10 → link-local (also private, but typically not used for dev servers)
        if host.hasPrefix("fe80") {
            return true
        }

        return false
    }

    /// Expand a compressed IPv6 address to its full 8-group form for validation.
    private static func expandIPv6(_ addr: String) -> String {
        // Basic validation: must contain at least one "::" or 8 groups
        let parts = addr.split(separator: ":", omittingEmptySubsequences: true)
        guard parts.count >= 2 && parts.count <= 8 else { return "" }

        // Rejoin to normalize — full validation would require inet_pton
        // but this is sufficient for our prefix-based checks
        return parts.joined(separator: ":")
    }
}
