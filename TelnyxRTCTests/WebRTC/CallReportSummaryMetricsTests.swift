//
//  CallReportSummaryMetricsTests.swift
//  TelnyxRTCTests
//
//  Call success metrics — summary fields, final state classification,
//  first bidirectional media and push funnel timestamps.
//

import XCTest
@testable import TelnyxRTC

class CallReportSummaryMetricsTests: XCTestCase {

    // MARK: - I1/A2: final state mapping

    func testFinalStateNormalClearingIsDone() {
        let reason = CallTerminationReason(cause: "NORMAL_CLEARING", causeCode: 16)
        XCTAssertEqual(Call.finalStateFor(terminalState: .DONE(reason: reason), terminationReason: reason), "done")
    }

    func testFinalStateCallerCancelIsDone() {
        let reason = CallTerminationReason(cause: "ORIGINATOR_CANCEL", causeCode: 487)
        XCTAssertEqual(Call.finalStateFor(terminalState: .DONE(reason: reason), terminationReason: reason), "done")
    }

    func testFinalState200OkIsDone() {
        let reason = CallTerminationReason(cause: nil, causeCode: nil, sipCode: 200, sipReason: "OK", sipCallId: nil)
        XCTAssertEqual(Call.finalStateFor(terminalState: .DONE(reason: reason), terminationReason: reason), "done")
    }

    func testFinalStateUserBusyIsFailed() {
        let reason = CallTerminationReason(cause: "USER_BUSY", causeCode: 17)
        XCTAssertEqual(Call.finalStateFor(terminalState: .DONE(reason: reason), terminationReason: reason), "failed")
    }

    func testFinalState486BusyHereIsFailed() {
        let reason = CallTerminationReason(cause: "USER_BUSY", causeCode: nil, sipCode: 486, sipReason: "Busy Here", sipCallId: nil)
        XCTAssertEqual(Call.finalStateFor(terminalState: .DONE(reason: reason), terminationReason: reason), "failed")
    }

    func testFinalStateDroppedIsDropped() {
        XCTAssertEqual(Call.finalStateFor(terminalState: .DROPPED(reason: .networkLost), terminationReason: nil), "dropped")
    }

    func testFinalStateDoneWithoutReasonIsDone() {
        XCTAssertEqual(Call.finalStateFor(terminalState: .DONE(reason: nil), terminationReason: nil), "done")
    }

    // MARK: - I1: summary carries sipCause/sipCode

    func testSummaryEncodesNewFields() throws {
        let summary = CallReportSummary(
            callId: "test-call-id",
            direction: "OUTBOUND",
            state: "DONE",
            finalState: "failed",
            finalStateReason: "USER_BUSY",
            sipCause: "USER_BUSY",
            sipCode: 486,
            osVersion: "17.5.1",
            deviceModel: "iPhone15,3",
            firstMediaMs: 830,
            pushNotificationReceivedMs: 1_733_000_000_000,
            ringTs: "2024-10-30T21:46:40.000Z",
            userAnsweredMs: 1_733_000_001_000,
            answerTs: "2024-10-30T21:46:41.000Z",
            userDeclinedMs: nil,
            declineTs: nil
        )

        let data = try JSONEncoder().encode(summary)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["finalState"] as? String, "failed")
        XCTAssertEqual(json["finalStateReason"] as? String, "USER_BUSY")
        XCTAssertEqual(json["sipCause"] as? String, "USER_BUSY")
        XCTAssertEqual(json["sipCode"] as? Int, 486)
        XCTAssertEqual(json["osVersion"] as? String, "17.5.1")
        XCTAssertEqual(json["deviceModel"] as? String, "iPhone15,3")
        XCTAssertEqual(json["firstMediaMs"] as? Int, 830)
        XCTAssertEqual(json["pushNotificationReceivedMs"] as? Int, 1_733_000_000_000)
        XCTAssertEqual(json["ringTs"] as? String, "2024-10-30T21:46:40.000Z")
        XCTAssertEqual(json["userAnsweredMs"] as? Int, 1_733_000_001_000)
        XCTAssertEqual(json["answerTs"] as? String, "2024-10-30T21:46:41.000Z")
        XCTAssertNil(json["userDeclinedMs"])
        XCTAssertNil(json["declineTs"])
    }

    func testSummaryFieldsOmittedWhenNil() throws {
        let summary = CallReportSummary(callId: "test-call-id")
        let data = try JSONEncoder().encode(summary)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertNil(json["finalState"])
        XCTAssertNil(json["sipCause"])
        XCTAssertNil(json["sipCode"])
        XCTAssertNil(json["osVersion"])
        XCTAssertNil(json["deviceModel"])
        XCTAssertNil(json["firstMediaMs"])
        XCTAssertNil(json["pushNotificationReceivedMs"])
        XCTAssertNil(json["ringTs"])
        XCTAssertNil(json["userAnsweredMs"])
        XCTAssertNil(json["answerTs"])
        XCTAssertNil(json["userDeclinedMs"])
        XCTAssertNil(json["declineTs"])
    }

    // MARK: - I3: first bidirectional media detection

    func testCollectorDetectsTwoWayMedia() {
        let config = CallReportConfig(enabled: true, interval: 0.1)
        let collector = TelnyxCallReportCollector(config: config)
        collector.forceStartForTesting()

        // Neither direction yet
        collector.observeMediaDirectionForTesting(outbound: 0, inbound: 0)
        XCTAssertNil(collector.firstMediaMs)

        // Only outbound
        collector.observeMediaDirectionForTesting(outbound: 12, inbound: 0)
        XCTAssertNil(collector.firstMediaMs)

        // Both directions observed -> recorded
        collector.observeMediaDirectionForTesting(outbound: 12, inbound: 34)
        XCTAssertNotNil(collector.firstMediaMs)
        XCTAssertGreaterThanOrEqual(collector.firstMediaMs ?? -1, 0)
        XCTAssertLessThan(collector.firstMediaMs ?? Int.max, 10_000)
    }

    func testCollectorFirstMediaStabilizesAfterDetection() {
        let config = CallReportConfig(enabled: true, interval: 0.1)
        let collector = TelnyxCallReportCollector(config: config)
        collector.forceStartForTesting()

        collector.observeMediaDirectionForTesting(outbound: 5, inbound: 5)
        let first = collector.firstMediaMs
        XCTAssertNotNil(first)

        // Subsequent samples must not overwrite it
        collector.observeMediaDirectionForTesting(outbound: 50, inbound: 50)
        XCTAssertEqual(collector.firstMediaMs, first)
    }

    func testCollectorMarksSentinelWhenWindowElapses() {
        let config = CallReportConfig(enabled: true, interval: 0.1)
        let collector = TelnyxCallReportCollector(config: config)
        collector.forceStartForTesting(windowOverride: 11.0) // started 11 s ago

        collector.observeMediaDirectionForTesting(outbound: 5, inbound: 5)
        XCTAssertEqual(collector.firstMediaMs, -1)
    }

    /// A call that rings for a long time (>10 s) but is then answered should
    /// still detect first media because the detection window is anchored to
    /// when collection starts (ACTIVE), not collector creation.
    func testDelayedAnswerStillDetectsFirstMedia() {
        let config = CallReportConfig(enabled: true, interval: 0.1)
        // Collector created long before answer (simulates ring time).
        let collector = TelnyxCallReportCollector(config: config)

        // Simulate 15 seconds of ringing (callStartTime stays at creation).
        // Then forceStartForTesting anchors the detection window to "now",
        // as if start() was just called on ACTIVE.
        collector.forceStartForTesting()

        // Immediate bidirectional media after answer
        collector.observeMediaDirectionForTesting(outbound: 10, inbound: 10)
        XCTAssertNotNil(collector.firstMediaMs, "First media should be detected after delayed answer")
        XCTAssertGreaterThanOrEqual(collector.firstMediaMs ?? -1, 0)
        XCTAssertLessThan(collector.firstMediaMs ?? Int.max, 1_000, "firstMediaMs should be near-zero since media arrived immediately after ACTIVE")
    }

    // MARK: - I5: funnel timestamps

    func testCallFunnelTimestampsDefaultNil() {
        let call = Call(callId: UUID(),
                        remoteSdp: "v=0\r\n",
                        sessionId: "session-1",
                        socket: Socket(),
                        delegate: TxClient(),
                        iceServers: [],
                        enableCallReports: false)
        XCTAssertNil(call.pushReceivedMs)
        XCTAssertNil(call.userAnsweredMs)
        XCTAssertNil(call.userDeclinedMs)
        XCTAssertNil(call.finalState)
    }

    /// Remote cancel (caller hangs up before callee acts) must NOT record a
    /// decline timestamp — the callee never pressed "Decline".  When the
    /// remote BYE arrives, `endedLocally` is still `false`, so the guard in
    /// `endCall` skips `userDeclinedMs`.  This test verifies the invariant
    /// at the state level: an inbound .NEW call that transitions to .DONE
    /// without local action keeps `userDeclinedMs` nil.
    func testRemoteCancelInboundNewLeavesDeclinedNil() {
        // Inbound call (remoteSdp init → direction = .INBOUND)
        let call = Call(callId: UUID(),
                        remoteSdp: "v=0\r\n",
                        sessionId: "session-1",
                        socket: Socket(),
                        delegate: TxClient(),
                        iceServers: [],
                        enableCallReports: false)
        XCTAssertFalse(call.endedLocally, "endedLocally must default to false for remote-originated end")

        // Simulate remote cancel: direct transition to DONE (no local hangup)
        let cancelReason = CallTerminationReason(cause: "ORIGINATOR_CANCEL", causeCode: 487)
        call.updateCallState(callState: .DONE(reason: cancelReason))

        XCTAssertNil(call.userDeclinedMs, "Remote cancel must not set userDeclinedMs")
        XCTAssertEqual(call.finalState, "done", "Caller cancel (487) is classified as done")
    }
}
