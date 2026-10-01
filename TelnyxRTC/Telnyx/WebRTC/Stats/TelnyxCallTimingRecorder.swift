//
//  TelnyxCallTimingRecorder.swift
//  TelnyxRTC
//
//  Records the call-establishment milestones for a single call so they can be
//  attached to the call-report payload and rendered by the Voice SDK stats UI.
//
//  Compatible with the cross-SDK/backend payload schema produced by the JS SDK
//  and the Android/Flutter SDK ports. Recording is independent of debug logging
//  and is wrapped in safe-no-op semantics so any instrumentation error can
//  never delay or fail the underlying call.
//
//  Each milestone is recorded exactly once per call establishment. The
//  recorder is owned by one Call/Peer pair so concurrent calls remain
//  isolated. Monotonic time is read through an injectable clock to keep
//  ordering deterministic in unit tests.
//

import Foundation

// MARK: - Milestone Schema

/// Canonical 19-step call-establishment timeline, shared with the JS SDK and
/// the Android/Flutter ports. Do not rename existing cases — server-side
/// stats page keys off these strings verbatim.
public enum CallTimingMilestone: String, CaseIterable, Codable {
    case callStart                   = "call_start"
    case peerCreated                 = "peer_created"
    case mediaDevicesAcquired        = "media_devices_acquired"
    case peerSetupComplete           = "peer_setup_complete"
    case sdpNegotiationStarted       = "sdp_negotiation_started"
    case sdpOfferAnswerGenerated     = "sdp_offer_answer_generated"
    case localDescriptionApplied     = "local_description_applied"
    case iceGatheringStarted         = "ice_gathering_started"
    case sdpSent                     = "sdp_sent"
    case firstIceCandidate           = "first_ice_candidate"
    case firstServerReflexiveOrRelay = "first_server_reflexive_or_relay"
    case iceGatheringComplete        = "ice_gathering_complete"
    case remoteRinging               = "remote_ringing"
    case answer                      = "answer"
    case firstRemoteAudioVideoTrack  = "first_remote_audio_video_track"
    case remoteDescriptionApplied    = "remote_description_applied"
    case callActive                  = "call_active"
    case iceConnected                = "ice_connected"
    case dtlsConnected               = "dtls_connected"

    /// Stable ordering used by the backend when rendering the timeline.
    public var order: Int {
        switch self {
        case .callStart:                   return 1
        case .peerCreated:                 return 2
        case .mediaDevicesAcquired:        return 3
        case .peerSetupComplete:           return 4
        case .sdpNegotiationStarted:       return 5
        case .sdpOfferAnswerGenerated:     return 6
        case .localDescriptionApplied:     return 7
        case .iceGatheringStarted:         return 8
        case .sdpSent:                     return 9
        case .firstIceCandidate:           return 10
        case .firstServerReflexiveOrRelay: return 11
        case .iceGatheringComplete:        return 12
        case .remoteRinging:               return 13
        case .answer:                      return 14
        case .firstRemoteAudioVideoTrack:  return 15
        case .remoteDescriptionApplied:    return 16
        case .callActive:                  return 17
        case .iceConnected:                return 18
        case .dtlsConnected:               return 19
        }
    }
}

// MARK: - Codable Payload

/// One milestone's two derived timing values: absolute time elapsed since the
/// call start and the delta from the previous recorded milestone. Either value
/// may be `nil` if the milestone was not recorded (unsupported on a given
/// direction, never reached, or skipped during recovery).
public struct CallTimingMilestoneEntry: Codable, Equatable {
    public let fromStartMs: Double?
    public let deltaMs: Double?

    public init(fromStartMs: Double?, deltaMs: Double?) {
        self.fromStartMs = fromStartMs
        self.deltaMs = deltaMs
    }
}

/// All 19 milestones encoded in the order expected by the stats page. Each
/// milestone is optional — the recorder emits `nil` for milestones that never
/// fired rather than fabricating a zero-duration placeholder (per the issue
/// "do not fabricate zero-duration milestones").
public struct CallTimingBreakdown: Codable, Equatable {
    public let callStart: CallTimingMilestoneEntry?
    public let peerCreated: CallTimingMilestoneEntry?
    public let mediaDevicesAcquired: CallTimingMilestoneEntry?
    public let peerSetupComplete: CallTimingMilestoneEntry?
    public let sdpNegotiationStarted: CallTimingMilestoneEntry?
    public let sdpOfferAnswerGenerated: CallTimingMilestoneEntry?
    public let localDescriptionApplied: CallTimingMilestoneEntry?
    public let iceGatheringStarted: CallTimingMilestoneEntry?
    public let sdpSent: CallTimingMilestoneEntry?
    public let firstIceCandidate: CallTimingMilestoneEntry?
    public let firstServerReflexiveOrRelay: CallTimingMilestoneEntry?
    public let iceGatheringComplete: CallTimingMilestoneEntry?
    public let remoteRinging: CallTimingMilestoneEntry?
    public let answer: CallTimingMilestoneEntry?
    public let firstRemoteAudioVideoTrack: CallTimingMilestoneEntry?
    public let remoteDescriptionApplied: CallTimingMilestoneEntry?
    public let callActive: CallTimingMilestoneEntry?
    public let iceConnected: CallTimingMilestoneEntry?
    public let dtlsConnected: CallTimingMilestoneEntry?

    public init(
        callStart: CallTimingMilestoneEntry? = nil,
        peerCreated: CallTimingMilestoneEntry? = nil,
        mediaDevicesAcquired: CallTimingMilestoneEntry? = nil,
        peerSetupComplete: CallTimingMilestoneEntry? = nil,
        sdpNegotiationStarted: CallTimingMilestoneEntry? = nil,
        sdpOfferAnswerGenerated: CallTimingMilestoneEntry? = nil,
        localDescriptionApplied: CallTimingMilestoneEntry? = nil,
        iceGatheringStarted: CallTimingMilestoneEntry? = nil,
        sdpSent: CallTimingMilestoneEntry? = nil,
        firstIceCandidate: CallTimingMilestoneEntry? = nil,
        firstServerReflexiveOrRelay: CallTimingMilestoneEntry? = nil,
        iceGatheringComplete: CallTimingMilestoneEntry? = nil,
        remoteRinging: CallTimingMilestoneEntry? = nil,
        answer: CallTimingMilestoneEntry? = nil,
        firstRemoteAudioVideoTrack: CallTimingMilestoneEntry? = nil,
        remoteDescriptionApplied: CallTimingMilestoneEntry? = nil,
        callActive: CallTimingMilestoneEntry? = nil,
        iceConnected: CallTimingMilestoneEntry? = nil,
        dtlsConnected: CallTimingMilestoneEntry? = nil
    ) {
        self.callStart = callStart
        self.peerCreated = peerCreated
        self.mediaDevicesAcquired = mediaDevicesAcquired
        self.peerSetupComplete = peerSetupComplete
        self.sdpNegotiationStarted = sdpNegotiationStarted
        self.sdpOfferAnswerGenerated = sdpOfferAnswerGenerated
        self.localDescriptionApplied = localDescriptionApplied
        self.iceGatheringStarted = iceGatheringStarted
        self.sdpSent = sdpSent
        self.firstIceCandidate = firstIceCandidate
        self.firstServerReflexiveOrRelay = firstServerReflexiveOrRelay
        self.iceGatheringComplete = iceGatheringComplete
        self.remoteRinging = remoteRinging
        self.answer = answer
        self.firstRemoteAudioVideoTrack = firstRemoteAudioVideoTrack
        self.remoteDescriptionApplied = remoteDescriptionApplied
        self.callActive = callActive
        self.iceConnected = iceConnected
        self.dtlsConnected = dtlsConnected
    }

    /// Snapshot the current breakdown in the canonical field-order expected by
    /// the backend. The closure receives every recorded entry keyed by its
    /// enum so callers can map without re-encoding each field manually.
    public static func snapshot(_ recorder: TelnyxCallTimingRecorder) -> CallTimingBreakdown {
        return recorder.breakdown()
    }
}

// MARK: - Clock

/// Monotonic time source used by `TelnyxCallTimingRecorder`. Swapping the
/// implementation lets tests freeze time without depending on `Date()`.
public protocol CallTimingClock {
    /// Monotonic nanoseconds. Successive calls must be non-decreasing.
    func nowNanoseconds() -> UInt64
    /// Monotonic milliseconds since the recorder's start. Computed internally
    /// so the recorder owns the reference point and tests can pin the offset.
    func elapsedMilliseconds(since startNanos: UInt64) -> Double
}

/// Default production clock — uses `mach_absolute_time` which is monotonic and
/// unaffected by wall-clock adjustments.
public final class MonotonicCallTimingClock: CallTimingClock {
    public init() {}

    public func nowNanoseconds() -> UInt64 {
        var info = mach_timebase_info()
        guard mach_timebase_info(&info) == KERN_SUCCESS else { return 0 }
        let ticks = mach_absolute_time()
        return ticks &* UInt64(info.numer) / UInt64(info.denom)
    }

    public func elapsedMilliseconds(since startNanos: UInt64) -> Double {
        let deltaNanos = nowNanoseconds().safeSubtract(startNanos)
        return Double(deltaNanos) / 1_000_000.0
    }
}

/// Test-only clock — caller-controlled monotonic time. Tests can advance time
/// deterministically between `record(_:)` calls.
public final class ManualCallTimingClock: CallTimingClock {
    private let lock = NSLock()
    private var currentNanos: UInt64

    public init(initialNanos: UInt64 = 0) {
        self.currentNanos = initialNanos
    }

    public func nowNanoseconds() -> UInt64 {
        lock.lock(); defer { lock.unlock() }
        return currentNanos
    }

    public func elapsedMilliseconds(since startNanos: UInt64) -> Double {
        lock.lock(); defer { lock.unlock() }
        let deltaNanos = currentNanos.safeSubtract(startNanos)
        return Double(deltaNanos) / 1_000_000.0
    }

    /// Advance the clock by the given number of milliseconds. Tests call this
    /// between `record(_:)` invocations to assert specific deltas.
    public func advance(byMilliseconds ms: Double) {
        lock.lock(); defer { lock.unlock() }
        let nanos = UInt64(max(0, ms * 1_000_000.0))
        currentNanos = currentNanos &+ nanos
    }
}

// MARK: - Recorder

/// Per-call recorder that captures the 19 call-establishment milestones and
/// exposes them as a `CallTimingBreakdown` for serialization into the
/// `CallReportPayload`. One instance per `Call` keeps concurrent calls fully
/// isolated. All public methods swallow errors — recording timing must never
/// delay, fail, or alter the outcome of the underlying call.
public final class TelnyxCallTimingRecorder {

    /// Direction of the call establishment. Recorded alongside the breakdown
    /// so the stats UI can disambiguate inbound vs outbound timelines when
    /// viewing a call report.
    public enum Direction: String, Codable {
        case outbound
        case inbound
        case attach
    }

    private let clock: CallTimingClock
    private let lock = NSLock()
    private var startNanos: UInt64?
    private var previousNanos: UInt64?
    private var entries: [CallTimingMilestone: UInt64] = [:]
    private var recordedDirection: Direction?

    /// Stable identifier for the call this recorder belongs to. Surfaced in
    /// logs so concurrent-call logs can be disambiguated.
    public let callId: String?

    public init(callId: String? = nil,
                clock: CallTimingClock = MonotonicCallTimingClock()) {
        self.callId = callId
        self.clock = clock
    }

    // MARK: Recording

    /// Begin the establishment timeline. Must be called exactly once per call,
    /// as early as possible in the lifecycle (typically from the Call
    /// initializer on the outbound side, or from the incoming-call handler on
    /// the inbound side).
    public func start(direction: Direction) {
        lock.lock(); defer { lock.unlock() }
        guard startNanos == nil else { return }
        let now = clock.nowNanoseconds()
        startNanos = now
        previousNanos = now
        recordedDirection = direction
        entries[.callStart] = now
    }

    /// Record a milestone. Milestones are recorded once per establishment
    /// generation — subsequent calls for the same milestone are no-ops so the
    /// timeline is never reset by reconnect/ICE-restart/recovery paths.
    public func record(_ milestone: CallTimingMilestone) {
        lock.lock(); defer { lock.unlock() }
        guard let start = startNanos, let prev = previousNanos else { return }
        guard entries[milestone] == nil else { return }
        let now = clock.nowNanoseconds()
        entries[milestone] = now
        previousNanos = now
        _ = start
        _ = prev
    }

    /// Snapshot the current breakdown. Safe to call from any thread. Returns
    /// a value with `nil` for any milestone that has not yet been recorded.
    public func breakdown() -> CallTimingBreakdown {
        lock.lock()
        let start = startNanos
        let snapshot = entries
        let dir = recordedDirection
        lock.unlock()

        guard let startNanos = start else {
            return CallTimingBreakdown()
        }

        func entry(_ milestone: CallTimingMilestone) -> CallTimingMilestoneEntry? {
            guard let recordedNanos = snapshot[milestone] else { return nil }
            let fromStartNanos = recordedNanos.safeSubtract(startNanos)
            let fromStartMs = Double(fromStartNanos) / 1_000_000.0

            // Delta = recorded_nanos - previous_recorded_nanos (chronological
            // predecessor in milestone order, not recording order). This
            // matches the cross-SDK/backend interpretation.
            let predecessor = CallTimingMilestone.allCases
                .filter { $0.order < milestone.order }
                .filter { snapshot[$0] != nil }
                .sorted { $0.order > $1.order }
                .first
            let deltaMs: Double?
            if let predecessor = predecessor, let prevNanos = snapshot[predecessor] {
                let deltaNanos = recordedNanos.safeSubtract(prevNanos)
                deltaMs = Double(deltaNanos) / 1_000_000.0
            } else {
                deltaMs = nil
            }
            return CallTimingMilestoneEntry(fromStartMs: fromStartMs, deltaMs: deltaMs)
        }

        _ = dir // direction is encoded into the call report summary; not duplicated here.

        return CallTimingBreakdown(
            callStart: entry(.callStart),
            peerCreated: entry(.peerCreated),
            mediaDevicesAcquired: entry(.mediaDevicesAcquired),
            peerSetupComplete: entry(.peerSetupComplete),
            sdpNegotiationStarted: entry(.sdpNegotiationStarted),
            sdpOfferAnswerGenerated: entry(.sdpOfferAnswerGenerated),
            localDescriptionApplied: entry(.localDescriptionApplied),
            iceGatheringStarted: entry(.iceGatheringStarted),
            sdpSent: entry(.sdpSent),
            firstIceCandidate: entry(.firstIceCandidate),
            firstServerReflexiveOrRelay: entry(.firstServerReflexiveOrRelay),
            iceGatheringComplete: entry(.iceGatheringComplete),
            remoteRinging: entry(.remoteRinging),
            answer: entry(.answer),
            firstRemoteAudioVideoTrack: entry(.firstRemoteAudioVideoTrack),
            remoteDescriptionApplied: entry(.remoteDescriptionApplied),
            callActive: entry(.callActive),
            iceConnected: entry(.iceConnected),
            dtlsConnected: entry(.dtlsConnected)
        )
    }

    /// Reset all recorded milestones. Used at the start of a fresh
    /// establishment generation when the SDK intentionally discards the
    /// previous timeline (rare — reconnect/ICE-restart keeps the original).
    public func reset() {
        lock.lock(); defer { lock.unlock() }
        startNanos = nil
        previousNanos = nil
        entries.removeAll()
        recordedDirection = nil
    }

    // MARK: Inspection (test-only / debug)

    /// Returns the count of recorded milestones. Intended for unit tests and
    /// structured logging; not used by the report payload.
    public func recordedCount() -> Int {
        lock.lock(); defer { lock.unlock() }
        return entries.count
    }
}

// MARK: - UInt64 helpers

private extension UInt64 {
    /// Saturating subtraction — guards against clock implementations that
    /// could (incorrectly) report a value lower than `start`. Always returns
    /// a non-negative delta.
    func safeSubtract(_ other: UInt64) -> UInt64 {
        return self >= other ? self - other : 0
    }
}
