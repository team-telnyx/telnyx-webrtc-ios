//
//  TelnyxCallTimingRecorderTests.swift
//  TelnyxRTCTests
//
//  Unit tests for the per-call call-establishment timing recorder.
//  Uses the bundled `ManualCallTimingClock` so milestones and elapsed
//  deltas are deterministic and independent of wall-clock time. Covers
//  the canonical 19-step schema, once-per-milestone dedup, schema
//  snapshot stability, concurrent-call isolation, and the cross-SDK
//  payload compatibility contract (field names + values).
//
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import XCTest
@testable import TelnyxRTC

class TelnyxCallTimingRecorderTests: XCTestCase {

    // MARK: - Init / start

    func testStartSeedsCallStartMilestone() {
        let clock = ManualCallTimingClock()
        let recorder = TelnyxCallTimingRecorder(clock: clock)

        recorder.start(direction: .outbound)

        let breakdown = recorder.breakdown()
        XCTAssertNotNil(breakdown.callStart, "callStart must be recorded by start()")
        // First entry's fromStartMs is 0 (no predecessor other than itself).
        XCTAssertEqual(breakdown.callStart?.fromStartMs, 0.0, accuracy: 0.001)
        XCTAssertNil(breakdown.callStart?.deltaMs, "callStart has no predecessor")
        // No other milestones should be present yet.
        XCTAssertNil(breakdown.peerCreated)
        XCTAssertNil(breakdown.mediaDevicesAcquired)
    }

    func testStartIsIdempotent() {
        let clock = ManualCallTimingClock()
        let recorder = TelnyxCallTimingRecorder(clock: clock)

        recorder.start(direction: .outbound)
        clock.advance(byMilliseconds: 100)
        recorder.start(direction: .inbound) // must NOT reset startNanos

        let b = recorder.breakdown()
        XCTAssertNotNil(b.callStart)
        // The callStart fromStartMs stays 0 because start() is no-op on re-entry.
        XCTAssertEqual(b.callStart?.fromStartMs, 0.0, accuracy: 0.001)
        XCTAssertEqual(recorder.recordedCount(), 1)
    }

    // MARK: - Recording

    func testRecordOncePerMilestone() {
        let clock = ManualCallTimingClock()
        let recorder = TelnyxCallTimingRecorder(clock: clock)
        recorder.start(direction: .outbound)

        recorder.record(.peerCreated)
        recorder.record(.peerCreated) // duplicate — must be ignored
        recorder.record(.peerCreated) // duplicate — must be ignored

        XCTAssertEqual(recorder.recordedCount(), 2) // callStart + peerCreated only
        XCTAssertNotNil(recorder.breakdown().peerCreated)
    }

    func testFromStartAndDeltaMath() {
        let clock = ManualCallTimingClock()
        let recorder = TelnyxCallTimingRecorder(clock: clock)
        recorder.start(direction: .outbound)

        clock.advance(byMilliseconds: 50)
        recorder.record(.peerCreated)

        clock.advance(byMilliseconds: 30)
        recorder.record(.mediaDevicesAcquired)

        clock.advance(byMilliseconds: 20)
        recorder.record(.peerSetupComplete)

        let b = recorder.breakdown()
        XCTAssertEqual(b.peerCreated?.fromStartMs ?? 0, 50.0, accuracy: 0.001)
        XCTAssertEqual(b.peerCreated?.deltaMs ?? 0, 50.0, accuracy: 0.001) // vs callStart

        XCTAssertEqual(b.mediaDevicesAcquired?.fromStartMs ?? 0, 80.0, accuracy: 0.001)
        XCTAssertEqual(b.mediaDevicesAcquired?.deltaMs ?? 0, 30.0, accuracy: 0.001) // vs peerCreated

        XCTAssertEqual(b.peerSetupComplete?.fromStartMs ?? 0, 100.0, accuracy: 0.001)
        XCTAssertEqual(b.peerSetupComplete?.deltaMs ?? 0, 20.0, accuracy: 0.001) // vs mediaDevicesAcquired
    }

    func testDeltaComputedAgainstCanonicalPredecessor() {
        // Even if the user records .iceConnected before .peerCreated, the
        // delta must be computed against the canonical predecessor
        // (callStart) — not the actual recording order. This matches the
        // cross-SDK/backend interpretation.
        let clock = ManualCallTimingClock()
        let recorder = TelnyxCallTimingRecorder(clock: clock)
        recorder.start(direction: .outbound)

        clock.advance(byMilliseconds: 1)
        recorder.record(.iceConnected) // order=18, but recorded first

        let b = recorder.breakdown()
        XCTAssertEqual(b.iceConnected?.fromStartMs ?? 0, 1.0, accuracy: 0.001)
        XCTAssertEqual(b.iceConnected?.deltaMs ?? 0, 1.0, accuracy: 0.001, // vs callStart
            "delta must use the canonical predecessor (callStart), not the recording order")
    }

    // MARK: - Schema / cross-SDK compatibility

    func testAllNineteenCanonicalMilestonesExist() {
        // The recorder MUST export all 19 canonical milestones. Adding
        // cases is allowed (in fact, used by some integrations) but
        // removing any of these breaks cross-SDK/backend parity.
        let canonical: Set<String> = [
            "call_start",
            "peer_created",
            "media_devices_acquired",
            "peer_setup_complete",
            "sdp_negotiation_started",
            "sdp_offer_answer_generated",
            "local_description_applied",
            "ice_gathering_started",
            "sdp_sent",
            "first_ice_candidate",
            "first_server_reflexive_or_relay",
            "ice_gathering_complete",
            "remote_ringing",
            "answer",
            "first_remote_audio_video_track",
            "remote_description_applied",
            "call_active",
            "ice_connected",
            "dtls_connected",
        ]
        let actual = Set(CallTimingMilestone.allCases.map { $0.rawValue })
        XCTAssertEqual(actual, canonical, "Milestone schema drifted from canonical 19-step list")
    }

    func testBreakdownEncodesEveryCanonicalKey() {
        // The Codable payload uses the snake_case rawValues as keys; the
        // backend stats UI keys off these strings verbatim. A change to
        // any rawValue would silently break rendering for every call.
        let clock = ManualCallTimingClock()
        let recorder = TelnyxCallTimingRecorder(clock: clock)
        recorder.start(direction: .outbound)
        recorder.record(.peerCreated)
        recorder.record(.mediaDevicesAcquired)
        recorder.record(.peerSetupComplete)
        recorder.record(.sdpNegotiationStarted)
        recorder.record(.sdpOfferAnswerGenerated)
        recorder.record(.localDescriptionApplied)
        recorder.record(.iceGatheringStarted)
        recorder.record(.sdpSent)
        recorder.record(.firstIceCandidate)
        recorder.record(.firstServerReflexiveOrRelay)
        recorder.record(.iceGatheringComplete)
        recorder.record(.remoteRinging)
        recorder.record(.answer)
        recorder.record(.firstRemoteAudioVideoTrack)
        recorder.record(.remoteDescriptionApplied)
        recorder.record(.callActive)
        recorder.record(.iceConnected)
        recorder.record(.dtlsConnected)

        let breakdown = recorder.breakdown()
        let data = (try? JSONEncoder().encode(breakdown)) ?? Data()
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]

        let expectedKeys: Set<String> = [
            "call_start", "peer_created", "media_devices_acquired",
            "peer_setup_complete", "sdp_negotiation_started",
            "sdp_offer_answer_generated", "local_description_applied",
            "ice_gathering_started", "sdp_sent", "first_ice_candidate",
            "first_server_reflexive_or_relay", "ice_gathering_complete",
            "remote_ringing", "answer", "first_remote_audio_video_track",
            "remote_description_applied", "call_active", "ice_connected",
            "dtls_connected",
        ]
        XCTAssertEqual(Set(json.keys), expectedKeys,
            "Serialized breakdown keys must match canonical snake_case schema")
    }

    // MARK: - Snapshot semantics

    func testBreakdownBeforeStartIsAllNil() {
        let recorder = TelnyxCallTimingRecorder()
        let b = recorder.breakdown()
        XCTAssertNil(b.callStart)
        XCTAssertNil(b.peerCreated)
        XCTAssertNil(b.mediaDevicesAcquired)
        XCTAssertNil(b.dtlsConnected)
    }

    func testResetClearsTimeline() {
        let clock = ManualCallTimingClock()
        let recorder = TelnyxCallTimingRecorder(clock: clock)
        recorder.start(direction: .outbound)
        recorder.record(.peerCreated)
        recorder.record(.mediaDevicesAcquired)
        XCTAssertEqual(recorder.recordedCount(), 3)

        recorder.reset()
        XCTAssertEqual(recorder.recordedCount(), 0)
        XCTAssertNil(recorder.breakdown().callStart)
        XCTAssertNil(recorder.breakdown().peerCreated)
    }

    // MARK: - Isolation

    func testConcurrentRecordersAreIndependent() {
        // Two recorders using the same clock must NOT share recorded
        // milestones. Each call (and thus each recorder) owns its own
        // timeline so concurrent calls stay isolated.
        let clock = ManualCallTimingClock()
        let r1 = TelnyxCallTimingRecorder(callId: "c1", clock: clock)
        let r2 = TelnyxCallTimingRecorder(callId: "c2", clock: clock)
        r1.start(direction: .outbound)
        r2.start(direction: .inbound)

        r1.record(.peerCreated)
        r2.record(.peerCreated)
        r1.record(.mediaDevicesAcquired)

        XCTAssertEqual(r1.recordedCount(), 3)
        XCTAssertEqual(r2.recordedCount(), 2)
    }

    // MARK: - Clock

    func testMonotonicClockIsNondecreasing() {
        let clock = MonotonicCallTimingClock()
        var prev = clock.nowNanoseconds()
        for _ in 0..<100 {
            let now = clock.nowNanoseconds()
            XCTAssertGreaterThanOrEqual(now, prev)
            prev = now
        }
    }

    func testManualClockAdvanceIsDeterministic() {
        let clock = ManualCallTimingClock(initialNanos: 0)
        let t0 = clock.nowNanoseconds()
        clock.advance(byMilliseconds: 10)
        let t1 = clock.nowNanoseconds()
        clock.advance(byMilliseconds: 25.5)
        let t2 = clock.nowNanoseconds()

        XCTAssertEqual(t1 - t0, 10_000_000, accuracy: 1)
        XCTAssertEqual(t2 - t1, 25_500_000, accuracy: 1)
    }

    // MARK: - Error semantics

    func testRecordBeforeStartIsNoOp() {
        let clock = ManualCallTimingClock()
        let recorder = TelnyxCallTimingRecorder(clock: clock)

        // Recording before start() must be a silent no-op — never crashes,
        // never records anything. This guarantees the recorder cannot
        // affect the outcome of the underlying call.
        recorder.record(.peerCreated)
        recorder.record(.mediaDevicesAcquired)
        XCTAssertEqual(recorder.recordedCount(), 0)
    }
}
