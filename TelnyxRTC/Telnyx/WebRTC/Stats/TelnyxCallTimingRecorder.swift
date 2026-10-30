//
//  TelnyxCallTimingRecorder.swift
//  TelnyxRTC
//
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import Foundation

/// Call-establishment milestones recorded for the call report.
enum CallTimingMilestone {
    case callStart
    case inviteReceived
    case answerInitiated
    case peerCreated
    case mediaDevicesAcquired
    case peerSetupComplete
    case sdpNegotiationStarted
    case localSdpCreated
    case localSdpSet
    case iceGatheringStarted
    case inviteSent
    case answerSent
    case firstIceCandidate
    case firstSrflxRelayCandidate
    case remoteRinging
    case earlyMedia
    case remoteSdpReceived
    case remoteSdpSet
    case iceGatheringComplete
    case iceConnected
    case dtlsConnected
    case callAnsweredByRemote
    case callActive
}

/// Records the call-establishment milestones of one call and turns them into the
/// `[CallTimings]` log block that the JS and Android SDKs add to call reports.
///
/// The block is emitted once through `onCallTimingsReady`, when the call is active and
/// DTLS has connected, whichever comes last. Like the JS SDK, calls that never get there
/// have no block.
final class TelnyxCallTimingRecorder {

    enum Direction: String {
        case outbound
        case inbound
    }

    /// Step labels and order shared with the JS and Android SDKs. The portal parses rows with
    /// `(?<step>.+?)\s{2,}(?<delta>[\d.]+ms|-)`, so labels must not change.
    private static let outboundSteps: [(milestone: CallTimingMilestone, label: String)] = [
        (.callStart, "Call Start"),
        (.peerCreated, "Peer object created"),
        (.mediaDevicesAcquired, "Media devices acquired"),
        (.peerSetupComplete, "Peer setup complete"),
        (.sdpNegotiationStarted, "SDP negotiation started"),
        (.localSdpCreated, "SDP offer generated"),
        (.localSdpSet, "Local description applied"),
        (.iceGatheringStarted, "ICE candidate gathering started"),
        (.inviteSent, "SDP sent to server"),
        (.firstIceCandidate, "First ICE candidate found"),
        (.firstSrflxRelayCandidate, "First server-reflexive/relay candidate found"),
        (.remoteRinging, "Remote side ringing"),
        (.earlyMedia, "Early media received from server"),
        (.remoteSdpReceived, "Remote SDP received"),
        (.remoteSdpSet, "Remote description applied"),
        (.iceGatheringComplete, "All ICE candidates gathered"),
        (.iceConnected, "ICE connection established"),
        (.dtlsConnected, "Secure media channel established (DTLS)"),
        (.callAnsweredByRemote, "Call answered by remote side"),
        (.callActive, "Call is active")
    ]

    private static let inboundSteps: [(milestone: CallTimingMilestone, label: String)] = [
        (.callStart, "Call Start"),
        (.inviteReceived, "Invite received"),
        (.answerInitiated, "Answer initiated"),
        (.peerCreated, "Peer object created"),
        (.mediaDevicesAcquired, "Media devices acquired"),
        (.peerSetupComplete, "Peer setup complete"),
        (.sdpNegotiationStarted, "SDP negotiation started"),
        (.localSdpCreated, "SDP answer generated"),
        (.localSdpSet, "Local description applied"),
        (.iceGatheringStarted, "ICE candidate gathering started"),
        (.firstIceCandidate, "First ICE candidate found"),
        (.firstSrflxRelayCandidate, "First server-reflexive/relay candidate found"),
        (.answerSent, "Answer sent to server"),
        (.remoteSdpReceived, "Remote SDP received"),
        (.remoteSdpSet, "Remote description applied"),
        (.iceGatheringComplete, "All ICE candidates gathered"),
        (.iceConnected, "ICE connection established"),
        (.dtlsConnected, "Secure media channel established (DTLS)"),
        (.callActive, "Call is active")
    ]

    /// Receives the `[CallTimings]` lines, once.
    var onCallTimingsReady: (([String]) -> Void)?

    private let direction: Direction
    private let mode: String
    private let now: () -> TimeInterval
    private let startTime: TimeInterval
    private let lock = NSLock()
    private var milestones: [CallTimingMilestone: TimeInterval] = [:]
    private var didEmit = false

    /// - Parameters:
    ///   - direction: Selects the outbound or inbound step list.
    ///   - useTrickleIce: Shown as the `trickle` or `standard` mode in the log prefix.
    ///   - now: Monotonic clock in seconds. Tests inject their own.
    init(direction: Direction,
         useTrickleIce: Bool,
         now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        self.direction = direction
        self.mode = useTrickleIce ? "trickle" : "standard"
        self.now = now
        self.startTime = now()
        self.milestones[.callStart] = startTime
    }

    /// Records `milestone` the first time it is reached. Later calls are ignored, so
    /// reconnects and ICE restarts keep the original establishment timeline.
    func record(_ milestone: CallTimingMilestone) {
        lock.lock()
        var lines: [String]?
        if milestones[milestone] == nil {
            milestones[milestone] = now()
            if !didEmit && milestones[.callActive] != nil && milestones[.dtlsConnected] != nil {
                didEmit = true
                lines = buildCallTimingsLines()
            }
        }
        lock.unlock()

        if let lines = lines {
            onCallTimingsReady?(lines)
        }
    }

    /// The `[CallTimings]` lines for the milestones recorded so far, without emitting them.
    func callTimingsLines() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return buildCallTimingsLines()
    }

    /// Must be called with `lock` held.
    private func buildCallTimingsLines() -> [String] {
        let prefix = "[CallTimings][\(direction.rawValue)][\(mode)]"
        let separator = "\(prefix) " + String(repeating: "-", count: 74)
        var lines = [
            "\(prefix) Call establishment timing breakdown:",
            "\(prefix)  Step  Delta  From Start",
            separator
        ]

        // Rows follow the time each step happened; the step list only breaks ties.
        let steps = direction == .outbound ? Self.outboundSteps : Self.inboundSteps
        let recordedSteps = steps.enumerated()
            .compactMap { index, step -> (index: Int, label: String, fromStartMs: Double)? in
                guard let time = milestones[step.milestone] else { return nil }
                return (index, step.label, (time - startTime) * 1000)
            }
            .sorted { ($0.fromStartMs, $0.index) < ($1.fromStartMs, $1.index) }

        var previousMs: Double?
        for step in recordedSteps {
            let delta = previousMs.map { Self.format(step.fromStartMs - $0) + "ms" } ?? "-"
            lines.append("\(prefix)  \(step.label)  \(delta)  \(Self.format(step.fromStartMs))ms")
            previousMs = step.fromStartMs
        }

        lines.append(separator)
        return lines
    }

    private static func format(_ milliseconds: Double) -> String {
        String(format: "%.2f", milliseconds)
    }
}
