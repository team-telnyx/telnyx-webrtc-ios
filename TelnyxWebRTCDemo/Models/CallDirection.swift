//
//  CallDirection.swift
//  TelnyxRTC
//
//  Created by Isaac Akakpo on 2025-06-05.
//
import Foundation
import CoreData
import Combine


extension CallHistoryEntry {
    /// Convenience computed property for call direction
    public var isIncoming: Bool {
        return direction == "incoming"
    }

    /// Convenience computed property for call direction
    public var isOutgoing: Bool {
        return direction == "outgoing"
    }

    /// Formatted duration string (e.g., "1:23")
    public var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Formatted timestamp for display
    public var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp ?? Date())
    }
}

public enum CallDirection: String, CaseIterable {
    case incoming = "incoming"
    case outgoing = "outgoing"
}

/// Call status enumeration
public enum CallStatus: String, CaseIterable {
    case answered = "answered"
    case missed = "missed"
    case rejected = "rejected"
    case failed = "failed"
    case cancelled = "cancelled"
}
