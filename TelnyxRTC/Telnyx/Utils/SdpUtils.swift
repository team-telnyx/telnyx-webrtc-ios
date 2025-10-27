//
//  SdpUtils.swift
//  TelnyxRTC
//
//  Created by Telnyx on 2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation

/// Utility class for Session Description Protocol (SDP) manipulation.
class SdpUtils {

    /// Adds trickle ICE capability to an SDP if not already present.
    /// This adds "a=ice-options:trickle" at the session level after the origin (o=) line.
    ///
    /// - Parameters:
    ///   - sdp: The original SDP string
    ///   - useTrickleIce: Whether trickle ICE is enabled
    /// - Returns: The modified SDP with ice-options:trickle added, or original if no modification needed
    static func addTrickleIceCapability(_ sdp: String, useTrickleIce: Bool) -> String {
        guard useTrickleIce else {
            return sdp
        }

        var lines = sdp.components(separatedBy: "\r\n")

        if let result = handleTrickleIceModification(&lines) {
            Logger.log.i(message: "SdpUtils :: Modified SDP with trickle ICE capability")
            return result
        } else {
            Logger.log.i(message: "SdpUtils :: SDP already contains trickle ICE or no modification needed")
            return sdp
        }
    }

    /// Handles trickle ICE modification by checking existing ice-options and adding if needed
    /// - Parameter lines: Array of SDP lines (passed as inout for modification)
    /// - Returns: Modified SDP string if changes were made, nil otherwise
    private static func handleTrickleIceModification(_ lines: inout [String]) -> String? {
        // Check if there's an existing ice-options line that needs modification
        if let existingIceOptionsIndex = findExistingIceOptionsIndex(lines) {
            return handleExistingIceOptions(&lines, at: existingIceOptionsIndex)
        }

        // If no existing ice-options line was found, try to add a new one
        return addNewIceOptions(&lines)
    }

    /// Finds the index of an existing ice-options line
    /// - Parameter lines: Array of SDP lines
    /// - Returns: Index of ice-options line, or nil if not found
    private static func findExistingIceOptionsIndex(_ lines: [String]) -> Int? {
        for (index, line) in lines.enumerated() {
            if line.hasPrefix("a=ice-options:") {
                return index
            }
        }
        return nil
    }

    /// Handles an existing ice-options line
    /// - Parameters:
    ///   - lines: Array of SDP lines (passed as inout for modification)
    ///   - index: Index of the existing ice-options line
    /// - Returns: Modified SDP string if changes were made, nil if already correct
    private static func handleExistingIceOptions(_ lines: inout [String], at index: Int) -> String? {
        let currentOptions = lines[index]

        if currentOptions == "a=ice-options:trickle" {
            // Already has exactly what we want
            return nil
        } else {
            // Replace any ice-options line with just trickle
            // This handles cases like "a=ice-options:trickle renomination"
            lines[index] = "a=ice-options:trickle"
            Logger.log.i(message: "SdpUtils :: Replaced ice-options line from '\(currentOptions)' to 'a=ice-options:trickle'")
            return lines.joined(separator: "\r\n")
        }
    }

    /// Adds a new ice-options line to the SDP
    /// - Parameter lines: Array of SDP lines (passed as inout for modification)
    /// - Returns: Modified SDP string if line was added, nil if origin line not found
    private static func addNewIceOptions(_ lines: inout [String]) -> String? {
        guard let insertIndex = findOriginLineInsertIndex(lines) else {
            Logger.log.w(message: "SdpUtils :: Could not find origin line in SDP, returning original")
            return nil
        }

        // Insert ice-options:trickle at session level (after origin line)
        lines.insert("a=ice-options:trickle", at: insertIndex)
        Logger.log.i(message: "SdpUtils :: Added a=ice-options:trickle to SDP at index \(insertIndex)")
        return lines.joined(separator: "\r\n")
    }

    /// Finds the index where the ice-options line should be inserted (after origin line)
    /// - Parameter lines: Array of SDP lines
    /// - Returns: Index after origin line, or nil if origin line not found
    private static func findOriginLineInsertIndex(_ lines: [String]) -> Int? {
        for (index, line) in lines.enumerated() {
            if line.hasPrefix("o=") {
                return index + 1
            }
        }
        return nil
    }

    /// Checks if an SDP contains trickle ICE capability.
    ///
    /// - Parameter sdp: The SDP string to check
    /// - Returns: true if the SDP advertises trickle ICE support
    static func hasTrickleIceCapability(_ sdp: String) -> Bool {
        return sdp.contains("a=ice-options:trickle")
    }

    /// Removes ICE candidates from SDP for trickle ICE
    ///
    /// - Parameter sdp: The SDP string to process
    /// - Returns: The SDP with ICE candidates removed
    static func removeIceCandidatesFromSdp(_ sdp: String) -> String {
        let lines = sdp.components(separatedBy: "\r\n")
        let modifiedLines = lines.filter { line in
            // Remove candidate lines (a=candidate:)
            !line.hasPrefix("a=candidate:")
        }

        let modifiedSdp = modifiedLines.joined(separator: "\r\n")
        Logger.log.i(message: "SdpUtils :: Removed ICE candidates from SDP for trickle ICE")
        return modifiedSdp
    }
}
