//
//  CallTimingBenchmark.swift
//  TelnyxRTC
//
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation

/// Helper class to track timing benchmarks during call connection.
/// Used to identify performance bottlenecks in the call setup process.
/// All benchmarks are collected and logged together when the call connects.
///
/// ## Usage:
/// - Call `start(isOutbound:)` when the call connection process begins
/// - Call `mark(_:)` at each milestone during the connection
/// - Call `markFirstCandidate()` when the first ICE candidate is gathered
/// - Call `end()` when the peer connection reaches the connected state
///
/// ## Inbound Call Milestones:
/// - media_stream_acquired: After getUserMedia()
/// - peer_connection_created: After RTCPeerConnection created
/// - remote_sdp_set: After setRemoteDescription()
/// - local_answer_created: After createAnswer()
/// - local_answer_sdp_set: After setLocalDescription()
/// - answer_sent: After sending answer message
/// - first_ice_candidate: First ICE candidate gathered
/// - ice_gathering_complete: All candidates gathered
/// - ice_state_*: ICE connection state transitions
/// - peer_state_*: Peer connection state transitions
///
/// ## Outbound Call Milestones:
/// - remote_answer_sdp_set: After setRemoteDescription() with answer SDP
/// - peer_state_*: Peer connection state transitions
public class CallTimingBenchmark {
    
    /// Singleton instance for tracking benchmarks across the call lifecycle
    public static let shared = CallTimingBenchmark()
    
    /// The start time of the benchmark
    private var startTime: Date?
    
    /// Dictionary of milestone names to elapsed time in milliseconds
    private var milestones: [String: Int] = [:]
    
    /// Flag to track if the first ICE candidate has been recorded
    private var isFirstCandidate: Bool = true
    
    /// Direction of the call (inbound or outbound)
    private var isOutbound: Bool = false
    
    /// Flag to track if the benchmark has ended (prevents duplicate end() calls)
    private var hasEnded: Bool = false
    
    /// Serial queue for thread-safe access to benchmark state
    private let queue = DispatchQueue(label: "com.telnyx.callTimingBenchmark")
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Starts the benchmark timer.
    ///
    /// - Parameter isOutbound: Indicates if this is an outbound call (true) or inbound (false).
    ///   For inbound calls, the timer starts when accept() is called.
    ///   For outbound calls, the timer starts when the answer SDP is received.
    public func start(isOutbound: Bool = false) {
        queue.sync {
            startTime = Date()
            milestones.removeAll()
            isFirstCandidate = true
            self.isOutbound = isOutbound
            hasEnded = false
            Logger.log.i(message: "CallTimingBenchmark :: Started benchmark timer for \(isOutbound ? "OUTBOUND" : "INBOUND") call")
        }
    }
    
    /// Records a milestone with the current elapsed time.
    ///
    /// - Parameter milestone: The name of the milestone to record.
    /// - Note: This method is thread-safe and will only record if the timer is running.
    public func mark(_ milestone: String) {
        queue.sync {
            guard let start = startTime, !hasEnded else {
                return
            }
            let elapsed = Int(Date().timeIntervalSince(start) * 1000) // Convert to milliseconds
            milestones[milestone] = elapsed
            Logger.log.i(message: "CallTimingBenchmark :: Milestone '\(milestone)' at \(elapsed)ms")
        }
    }
    
    /// Records the first ICE candidate (only once per call).
    /// Subsequent calls are ignored to track only the first candidate.
    public func markFirstCandidate() {
        queue.sync {
            guard startTime != nil, !hasEnded else {
                return
            }
            if isFirstCandidate {
                isFirstCandidate = false
                // Call mark outside of sync to avoid deadlock
            }
        }
        // Only mark if we were actually the first candidate
        if !isFirstCandidate {
            // Re-enter sync context safely
            let shouldMark = queue.sync { !hasEnded && startTime != nil }
            if shouldMark {
                mark("first_ice_candidate")
            }
        }
    }
    
    /// Ends the benchmark and logs a formatted summary of all milestones.
    /// This method is idempotent - subsequent calls after the first will be ignored.
    ///
    /// - Note: Call this when the peer connection reaches the "connected" state.
    public func end() {
        queue.sync {
            guard startTime != nil, !hasEnded else {
                return
            }
            hasEnded = true
        }
        
        // Get values safely
        let (total, direction, sortedMilestones) = queue.sync { () -> (Int, String, [(String, Int)]) in
            guard let start = startTime else {
                return (0, "", [])
            }
            let totalMs = Int(Date().timeIntervalSince(start) * 1000)
            let dir = isOutbound ? "OUTBOUND" : "INBOUND"
            
            // Sort milestones by time for chronological display
            let sorted = milestones.sorted { $0.value < $1.value }
            return (totalMs, dir, sorted)
        }
        
        guard total > 0 else { return }
        
        // Build the formatted output
        var output = "\n"
        output += "╔══════════════════════════════════════════════════════════╗\n"
        output += "║       \(direction) CALL CONNECTION BENCHMARK RESULTS       ║\n"
        output += "╠══════════════════════════════════════════════════════════╣\n"
        
        var previousTime: Int? = nil
        for (milestone, time) in sortedMilestones {
            let delta: String
            if let prev = previousTime {
                delta = "(+\(time - prev)ms)"
            } else {
                delta = ""
            }
            
            // Format the line with proper padding
            let milestonePadded = milestone.padding(toLength: 35, withPad: " ", startingAt: 0)
            let timePadded = String(format: "%6d", time)
            let deltaPadded = delta.isEmpty ? "          " : String(format: "%10s", (delta as NSString).utf8String!)
            
            output += "║  \(milestonePadded) \(timePadded)ms \(deltaPadded) ║\n"
            previousTime = time
        }
        
        output += "╠══════════════════════════════════════════════════════════╣\n"
        let totalPadded = String(format: "%6d", total)
        output += "║  TOTAL CONNECTION TIME:              \(totalPadded)ms            ║\n"
        output += "╚══════════════════════════════════════════════════════════╝\n"
        
        Logger.log.i(message: "CallTimingBenchmark ::\(output)")
    }
    
    /// Resets the benchmark state without logging.
    /// Useful for cleanup between calls.
    public func reset() {
        queue.sync {
            startTime = nil
            milestones.removeAll()
            isFirstCandidate = true
            isOutbound = false
            hasEnded = false
        }
    }
    
    /// Returns whether the benchmark is currently running.
    public var isRunning: Bool {
        return queue.sync { startTime != nil && !hasEnded }
    }
}
