//
//  CallHistoryEntry.swift
//  TelnyxWebRTCDemo
//
//  Created by AI SWE Agent on 02/06/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation
import CoreData

/// Represents a call history entry with all relevant call information
public class CallHistoryEntry: NSManagedObject {
    
    /// The unique identifier for this call
    @NSManaged public var callId: UUID
    
    /// The phone number or SIP URI that was called or received the call from
    @NSManaged public var phoneNumber: String
    
    /// The display name associated with the call (if available)
    @NSManaged public var callerName: String?
    
    /// The direction of the call (incoming/outgoing)
    @NSManaged public var direction: String
    
    /// The timestamp when the call was initiated
    @NSManaged public var timestamp: Date
    
    /// The duration of the call in seconds (0 if call was not answered)
    @NSManaged public var duration: Int32
    
    /// The final state of the call (answered, missed, rejected, etc.)
    @NSManaged public var callStatus: String
    
    /// The profile/user identifier this call belongs to
    @NSManaged public var profileId: String
    
    /// Additional metadata about the call (JSON string)
    @NSManaged public var metadata: String?
    
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
        return formatter.string(from: timestamp)
    }
}

/// Call direction enumeration
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