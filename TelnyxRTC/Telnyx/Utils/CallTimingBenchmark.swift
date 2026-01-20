//
//  CallTimingBenchmark.swift
//  TelnyxRTC
//
//  Created by AI Assistant on 20/01/2026.
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import Foundation

/// Constants for call connection benchmarking milestones
public enum CallBenchmarkMilestone {
    // Call initiation milestones
    public static let inviteStarted = "invite_started"
    public static let acceptCallStarted = "accept_call_started"
    
    // SDP processing milestones
    public static let answerSdpSent = "answer_sdp_sent"
    public static let answerSdpReceived = "answer_sdp_received"
    public static let remoteDescriptionSet = "remote_description_set"
    
    // ICE gathering states
    public static let iceGatheringNew = "ice_gathering_new"
    public static let iceGatheringGathering = "ice_gathering_gathering"
    public static let iceGatheringComplete = "ice_gathering_complete"
    
    // ICE connection states
    public static let iceStateChecking = "ice_state_checking"
    public static let iceStateConnected = "ice_state_connected"
    public static let iceStateCompleted = "ice_state_completed"
    public static let iceStateFailed = "ice_state_failed"
    public static let iceStateDisconnected = "ice_state_disconnected"
    public static let iceStateClosed = "ice_state_closed"
    
    // Peer connection states
    public static let peerStateConnecting = "peer_state_connecting"
    public static let peerStateConnected = "peer_state_connected"
    public static let peerStateDisconnected = "peer_state_disconnected"
    public static let peerStateFailed = "peer_state_failed"
    public static let peerStateClosed = "peer_state_closed"
    
    // ICE candidate milestones
    public static let firstIceCandidate = "first_ice_candidate"
}

/// Helper class to track timing benchmarks during call connection.
/// Used to identify performance bottlenecks in the call setup process.
/// All benchmarks are collected and logged together when the call connects.
/// Thread-safe singleton implementation that tracks call connection milestones.
public class CallTimingBenchmark {
    
    /// Shared instance for global access
    private static let shared = CallTimingBenchmark()
    
    /// Synchronization queue for thread safety
    private let queue = DispatchQueue(label: "com.telnyx.benchmarking", attributes: .concurrent)
    
    /// Timer for tracking total connection time
    private var totalTimer: Date?
    
    /// Dictionary storing milestone names and their elapsed times
    private var milestones: [String: TimeInterval] = [:]
    
    /// Flag to track if first ICE candidate has been recorded
    private var isFirstCandidate = true
    
    /// Flag to indicate if this is an outbound call
    private var isOutbound = false
    
    /// Flag to indicate if benchmarking is currently active
    private var isActive = false
    
    /// Private initializer for singleton pattern
    private init() {}
    
    // MARK: - Public Interface
    
    /// Starts the benchmark timer.
    /// - Parameter isOutbound: indicates if this is an outbound call (true) or inbound (false).
    public static func start(isOutbound: Bool = false) {
        shared.queue.async(flags: .barrier) {
            shared.totalTimer = Date()
            shared.milestones.removeAll()
            shared.isFirstCandidate = true
            shared.isOutbound = isOutbound
            shared.isActive = true
            
            Logger.log.i(message: "CallTimingBenchmark:: Started \(isOutbound ? "OUTBOUND" : "INBOUND") call benchmarking")
        }
    }
    
    /// Records a milestone with the current elapsed time.
    /// - Parameter milestone: The name of the milestone to record
    public static func mark(_ milestone: String) {
        shared.queue.async(flags: .barrier) {
            guard shared.isActive, let startTime = shared.totalTimer else {
                return
            }
            
            let elapsedTime = Date().timeIntervalSince(startTime) * 1000 // Convert to milliseconds
            shared.milestones[milestone] = elapsedTime
            
            Logger.log.i(message: "CallTimingBenchmark:: Marked '\(milestone)' at \(Int(elapsedTime))ms")
        }
    }
    
    /// Records the first ICE candidate (only once per call).
    public static func markFirstCandidate() {
        shared.queue.async(flags: .barrier) {
            guard shared.isActive, shared.isFirstCandidate else {
                return
            }
            
            shared.isFirstCandidate = false
            mark(CallBenchmarkMilestone.firstIceCandidate)
        }
    }
    
    /// Ends the benchmark and logs a formatted summary of all milestones.
    public static func end() {
        shared.queue.async(flags: .barrier) {
            guard shared.isActive, let startTime = shared.totalTimer else {
                return
            }
            
            shared.isActive = false
            let totalTime = Date().timeIntervalSince(startTime) * 1000 // Convert to milliseconds
            let direction = shared.isOutbound ? "OUTBOUND" : "INBOUND"
            
            // Build the formatted output
            var output = "\n"
            output += "╔══════════════════════════════════════════════════════════╗\n"
            output += "║       \(direction) CALL CONNECTION BENCHMARK RESULTS          ║\n"
            output += "╠══════════════════════════════════════════════════════════╣\n"
            
            // Sort milestones by time for chronological display
            let sortedMilestones = shared.milestones.sorted { $0.value < $1.value }
            
            var previousTime: TimeInterval?
            for (milestone, time) in sortedMilestones {
                let delta = previousTime != nil ? time - previousTime! : time
                let deltaString = previousTime != nil ? "(+\(Int(delta))ms)" : ""
                
                let milestoneFormatted = String(milestone.padding(toLength: 35, withPad: " ", startingAt: 0))
                let timeFormatted = String("\(Int(time))ms".padding(toLength: 6, withPad: " ", startingAt: 0))
                let deltaFormatted = String(deltaString.padding(toLength: 10, withPad: " ", startingAt: 0))
                
                output += "║  \(milestoneFormatted) \(timeFormatted) \(deltaFormatted) ║\n"
                previousTime = time
            }
            
            output += "╠══════════════════════════════════════════════════════════╣\n"
            output += "║  TOTAL CONNECTION TIME: \(String("\(Int(totalTime))ms".padding(toLength: 6, withPad: " ", startingAt: 0))) ║\n"
            output += "╚══════════════════════════════════════════════════════════╝"
            
            Logger.log.i(message: "CallTimingBenchmark:: \(output)")
        }
    }
    
    /// Resets the benchmark state for the next call.
    public static func reset() {
        shared.queue.async(flags: .barrier) {
            shared.totalTimer = nil
            shared.milestones.removeAll()
            shared.isFirstCandidate = true
            shared.isOutbound = false
            shared.isActive = false
            
            Logger.log.i(message: "CallTimingBenchmark:: Reset benchmark state")
        }
    }
    
    /// Checks if a benchmark is currently active.
    /// - Returns: true if benchmarking is currently running, false otherwise
    public static func isRunning() -> Bool {
        return shared.queue.sync {
            return shared.isActive
        }
    }
}
