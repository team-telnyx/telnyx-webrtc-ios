//
//  CallHistoryManager.swift
//  TelnyxWebRTCDemo
//
//  Created by AI SWE Agent on 02/06/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation
import TelnyxRTC
import CallKit

/// Manager class to handle call history tracking and integration
public class CallHistoryManager: ObservableObject {
    
    /// Shared singleton instance
    public static let shared = CallHistoryManager()
    
    /// Database instance
    private let database = CallHistoryDatabase.shared
    
    /// Dictionary to track active calls and their start times
    private var activeCallsStartTime: [UUID: Date] = [:]
    
    /// Dictionary to track call information for history
    private var callInfoCache: [UUID: CallInfo] = [:]
    
    /// Current profile identifier
    public var currentProfileId: String = "default"
    
    private init() {}
    
    // MARK: - Call Info Structure
    
    struct CallInfo {
        let phoneNumber: String
        let callerName: String?
        let direction: CallDirection
        let profileId: String
    }
    
    // MARK: - Public Methods
    
    /// Track the start of a call
    /// - Parameters:
    ///   - callId: Unique call identifier
    ///   - phoneNumber: Phone number or SIP URI
    ///   - callerName: Display name (optional)
    ///   - direction: Call direction
    ///   - profileId: Profile identifier (optional, uses current if nil)
    public func trackCallStart(
        callId: UUID,
        phoneNumber: String,
        callerName: String? = nil,
        direction: CallDirection,
        profileId: String? = nil
    ) {
        let profile = profileId ?? currentProfileId
        
        // Cache call information
        callInfoCache[callId] = CallInfo(
            phoneNumber: phoneNumber,
            callerName: callerName,
            direction: direction,
            profileId: profile
        )
        
        // Record start time
        activeCallsStartTime[callId] = Date()
        
        print("CallHistoryManager: Tracking call start - \(callId) (\(direction.rawValue))")
    }
    
    /// Track the end of a call
    /// - Parameters:
    ///   - callId: Unique call identifier
    ///   - status: Final call status
    public func trackCallEnd(callId: UUID, status: CallStatus) {
        guard let callInfo = callInfoCache[callId] else {
            print("CallHistoryManager: No cached info for call \(callId)")
            return
        }
        
        let duration = calculateCallDuration(for: callId)
        
        // Add to call history
        database.addCallHistoryEntry(
            callId: callId,
            phoneNumber: callInfo.phoneNumber,
            callerName: callInfo.callerName,
            direction: callInfo.direction,
            duration: Int32(duration),
            status: status,
            profileId: callInfo.profileId
        )
        
        // Clean up tracking data
        activeCallsStartTime.removeValue(forKey: callId)
        callInfoCache.removeValue(forKey: callId)
        
        print("CallHistoryManager: Tracked call end - \(callId) (\(status.rawValue), \(duration)s)")
    }
    
    /// Update call status for an active call
    /// - Parameters:
    ///   - callId: Unique call identifier
    ///   - status: Updated call status
    public func updateCallStatus(callId: UUID, status: CallStatus) {
        let duration = calculateCallDuration(for: callId)
        database.updateCallHistoryEntry(
            callId: callId,
            duration: Int32(duration),
            status: status
        )
        
        print("CallHistoryManager: Updated call status - \(callId) (\(status.rawValue))")
    }
    
    /// Handle CXStartCallAction (outgoing call)
    /// - Parameters:
    ///   - action: CXStartCallAction from CallKit
    ///   - phoneNumber: Destination phone number
    ///   - callerName: Caller name (optional)
    public func handleStartCallAction(
        action: CXStartCallAction,
        phoneNumber: String,
        callerName: String? = nil
    ) {
        trackCallStart(
            callId: action.callUUID,
            phoneNumber: phoneNumber,
            callerName: callerName,
            direction: .outgoing
        )
    }
    
    /// Handle CXAnswerCallAction (incoming call answered)
    /// - Parameters:
    ///   - action: CXAnswerCallAction from CallKit
    ///   - phoneNumber: Caller phone number
    ///   - callerName: Caller name (optional)
    public func handleAnswerCallAction(
        action: CXAnswerCallAction,
        phoneNumber: String,
        callerName: String? = nil
    ) {
        // Check if we already have this call tracked (from incoming call notification)
        if callInfoCache[action.callUUID] == nil {
            trackCallStart(
                callId: action.callUUID,
                phoneNumber: phoneNumber,
                callerName: callerName,
                direction: .incoming
            )
        }
        
        // Update status to answered
        updateCallStatus(callId: action.callUUID, status: .answered)
    }
    
    /// Handle incoming call notification (before answer/reject)
    /// - Parameters:
    ///   - callId: Unique call identifier
    ///   - phoneNumber: Caller phone number
    ///   - callerName: Caller name (optional)
    public func handleIncomingCall(
        callId: UUID,
        phoneNumber: String,
        callerName: String? = nil
    ) {
        trackCallStart(
            callId: callId,
            phoneNumber: phoneNumber,
            callerName: callerName,
            direction: .incoming
        )
    }
    
    /// Handle call rejection
    /// - Parameter callId: Unique call identifier
    public func handleCallRejected(callId: UUID) {
        trackCallEnd(callId: callId, status: .rejected)
    }
    
    /// Handle missed call
    /// - Parameter callId: Unique call identifier
    public func handleCallMissed(callId: UUID) {
        trackCallEnd(callId: callId, status: .missed)
    }
    
    /// Handle call failure
    /// - Parameter callId: Unique call identifier
    public func handleCallFailed(callId: UUID) {
        trackCallEnd(callId: callId, status: .failed)
    }
    
    /// Handle call cancellation
    /// - Parameter callId: Unique call identifier
    public func handleCallCancelled(callId: UUID) {
        trackCallEnd(callId: callId, status: .cancelled)
    }
    
    /// Get call history for current profile
    /// - Returns: Array of call history entries
    public func getCallHistory() -> [CallHistoryEntry] {
        return database.getCallHistory(for: currentProfileId)
    }
    
    /// Clear call history for current profile
    public func clearCallHistory() {
        database.clearCallHistory(for: currentProfileId)
    }
    
    /// Set the current profile ID
    /// - Parameter profileId: Profile identifier
    public func setCurrentProfile(_ profileId: String) {
        currentProfileId = profileId
    }
    
    // MARK: - Private Methods
    
    /// Calculate call duration for a given call ID
    /// - Parameter callId: Unique call identifier
    /// - Returns: Duration in seconds
    private func calculateCallDuration(for callId: UUID) -> TimeInterval {
        guard let startTime = activeCallsStartTime[callId] else {
            return 0
        }
        return Date().timeIntervalSince(startTime)
    }
}

// MARK: - Integration with TelnyxRTC

extension CallHistoryManager {
    
    /// Handle call state changes from TelnyxRTC Call object
    /// - Parameters:
    ///   - call: TelnyxRTC Call object
    ///   - previousState: Previous call state
    public func handleCallStateChange(call: Call, previousState: CallState?) {
        guard let callId = call.callInfo?.callId else { return }
        
        switch call.callState {
        case .ACTIVE:
            // Call became active (answered)
            if let callInfo = callInfoCache[callId] {
                updateCallStatus(callId: callId, status: .answered)
            }
            
        case .DONE(let reason):
            // Call ended
            let status: CallStatus
            if let terminationReason = reason?.cause {
                switch terminationReason {
                case "CALL_REJECTED":
                    status = .rejected
                case "ORIGINATOR_CANCEL":
                    status = .cancelled
                default:
                    status = activeCallsStartTime[callId] != nil ? .answered : .missed
                }
            } else {
                status = activeCallsStartTime[callId] != nil ? .answered : .missed
            }
            
            trackCallEnd(callId: callId, status: status)
            
        default:
            break
        }
    }
}