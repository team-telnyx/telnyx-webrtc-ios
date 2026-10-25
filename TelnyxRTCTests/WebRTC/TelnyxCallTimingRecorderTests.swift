//
//  TelnyxCallTimingRecorderTests.swift
//  TelnyxRTCTests
//
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import XCTest
import WebRTC
@testable import TelnyxRTC

/// Row pattern the portal uses to parse `[CallTimings]` lines, anchored to the full row.
private let callTimingsRowPattern = try! NSRegularExpression(
    pattern: #"^\[CallTimings\]\[(outbound|inbound)\]\[(trickle|standard)\]\s{2}(.+?)\s{2,}([\d.]+ms|-)\s{2,}([\d.]+ms)$"#
)

/// Step labels of the rows in a `[CallTimings]` block, in order.
private func stepLabels(_ lines: [String]) -> [String] {
    lines.compactMap { line in
        let range = NSRange(line.startIndex..., in: line)
        guard let match = callTimingsRowPattern.firstMatch(in: line, range: range),
              let stepRange = Range(match.range(at: 3), in: line) else {
            return nil
        }
        return String(line[stepRange])
    }
}

class TelnyxCallTimingRecorderTests: XCTestCase {

    private var currentTime: TimeInterval = 100

    private func makeRecorder(direction: TelnyxCallTimingRecorder.Direction,
                              useTrickleIce: Bool = true) -> TelnyxCallTimingRecorder {
        TelnyxCallTimingRecorder(direction: direction, useTrickleIce: useTrickleIce) { [unowned self] in
            self.currentTime
        }
    }

    private func advance(ms: Double) {
        currentTime += ms / 1000
    }

    func testBlockMatchesCallTimingsLogFormat() {
        let recorder = makeRecorder(direction: .outbound)
        advance(ms: 10)
        recorder.record(.peerCreated)
        advance(ms: 6)
        recorder.record(.localSdpCreated)

        let separator = "[CallTimings][outbound][trickle] " + String(repeating: "-", count: 74)
        XCTAssertEqual(recorder.callTimingsLines(), [
            "[CallTimings][outbound][trickle] Call establishment timing breakdown:",
            "[CallTimings][outbound][trickle]  Step  Delta  From Start",
            separator,
            "[CallTimings][outbound][trickle]  Call Start  -  0.00ms",
            "[CallTimings][outbound][trickle]  Peer object created  10.00ms  10.00ms",
            "[CallTimings][outbound][trickle]  SDP offer generated  6.00ms  16.00ms",
            separator
        ])
    }

    func testEveryOutboundStepRowMatchesPortalPattern() {
        let recorder = makeRecorder(direction: .outbound)
        let milestones: [CallTimingMilestone] = [
            .peerCreated, .mediaDevicesAcquired, .peerSetupComplete, .sdpNegotiationStarted,
            .localSdpCreated, .localSdpSet, .iceGatheringStarted, .inviteSent, .firstIceCandidate,
            .firstSrflxRelayCandidate, .remoteRinging, .earlyMedia, .remoteSdpReceived, .remoteSdpSet,
            .iceGatheringComplete, .iceConnected, .dtlsConnected, .callAnsweredByRemote, .callActive
        ]
        var lines: [String] = []
        recorder.onCallTimingsReady = { lines = $0 }
        milestones.forEach {
            advance(ms: 1)
            recorder.record($0)
        }

        XCTAssertEqual(stepLabels(lines), [
            "Call Start", "Peer object created", "Media devices acquired", "Peer setup complete",
            "SDP negotiation started", "SDP offer generated", "Local description applied",
            "ICE candidate gathering started", "SDP sent to server", "First ICE candidate found",
            "First server-reflexive/relay candidate found", "Remote side ringing",
            "Early media received from server", "Remote SDP received", "Remote description applied",
            "All ICE candidates gathered", "ICE connection established",
            "Secure media channel established (DTLS)", "Call answered by remote side", "Call is active"
        ])
    }

    func testEveryInboundStepRowMatchesPortalPattern() {
        let recorder = makeRecorder(direction: .inbound, useTrickleIce: false)
        let milestones: [CallTimingMilestone] = [
            .inviteReceived, .answerInitiated, .peerCreated, .mediaDevicesAcquired, .peerSetupComplete,
            .sdpNegotiationStarted, .localSdpCreated, .localSdpSet, .iceGatheringStarted,
            .firstIceCandidate, .firstSrflxRelayCandidate, .answerSent, .remoteSdpReceived,
            .remoteSdpSet, .iceGatheringComplete, .iceConnected, .dtlsConnected, .callActive
        ]
        var lines: [String] = []
        recorder.onCallTimingsReady = { lines = $0 }
        milestones.forEach {
            advance(ms: 1)
            recorder.record($0)
        }

        XCTAssertTrue(lines.allSatisfy { $0.hasPrefix("[CallTimings][inbound][standard]") })
        XCTAssertEqual(stepLabels(lines), [
            "Call Start", "Invite received", "Answer initiated", "Peer object created",
            "Media devices acquired", "Peer setup complete", "SDP negotiation started",
            "SDP answer generated", "Local description applied", "ICE candidate gathering started",
            "First ICE candidate found", "First server-reflexive/relay candidate found",
            "Answer sent to server", "Remote SDP received", "Remote description applied",
            "All ICE candidates gathered", "ICE connection established",
            "Secure media channel established (DTLS)", "Call is active"
        ])
    }

    func testStepsFromTheOtherDirectionAreLeftOut() {
        let recorder = makeRecorder(direction: .inbound)
        advance(ms: 1)
        recorder.record(.remoteRinging)
        recorder.record(.callAnsweredByRemote)
        recorder.record(.inviteSent)
        recorder.record(.answerSent)

        XCTAssertEqual(stepLabels(recorder.callTimingsLines()), ["Call Start", "Answer sent to server"])
    }

    func testRowsFollowTheTimeEachStepHappened() {
        let recorder = makeRecorder(direction: .outbound)
        advance(ms: 10)
        recorder.record(.dtlsConnected)
        advance(ms: 10)
        recorder.record(.iceConnected)

        let lines = recorder.callTimingsLines()
        XCTAssertEqual(stepLabels(lines), [
            "Call Start", "Secure media channel established (DTLS)", "ICE connection established"
        ])
        XCTAssertTrue(lines.contains("[CallTimings][outbound][trickle]  ICE connection established  10.00ms  20.00ms"))
    }

    func testMilestoneKeepsTheFirstRecordedTime() {
        let recorder = makeRecorder(direction: .outbound)
        advance(ms: 10)
        recorder.record(.peerCreated)
        advance(ms: 40)
        recorder.record(.peerCreated)

        XCTAssertTrue(recorder.callTimingsLines().contains("[CallTimings][outbound][trickle]  Peer object created  10.00ms  10.00ms"))
    }

    func testEmitsOnceWhenCallIsActiveAndDtlsConnectedInEitherOrder() {
        for order in [[CallTimingMilestone.callActive, .dtlsConnected], [.dtlsConnected, .callActive]] {
            let recorder = makeRecorder(direction: .outbound)
            var emitted: [[String]] = []
            recorder.onCallTimingsReady = { emitted.append($0) }

            recorder.record(order[0])
            XCTAssertTrue(emitted.isEmpty, "Must wait for both active and DTLS")
            recorder.record(order[1])
            recorder.record(.iceConnected)

            XCTAssertEqual(emitted.count, 1)
            XCTAssertTrue(stepLabels(emitted.first ?? []).contains("Call is active"))
        }
    }

    func testReadingLinesDoesNotEmit() {
        let recorder = makeRecorder(direction: .outbound)
        var emitted: [[String]] = []
        recorder.onCallTimingsReady = { emitted.append($0) }
        advance(ms: 5)
        recorder.record(.peerCreated)

        XCTAssertEqual(stepLabels(recorder.callTimingsLines()), ["Call Start", "Peer object created"])
        XCTAssertTrue(emitted.isEmpty)
    }
}

// MARK: - Peer milestones

class PeerCallTimingTests: XCTestCase {

    private var peer: Peer?

    override func tearDown() {
        peer?.connection?.close()
        peer = nil
        super.tearDown()
    }

    private func makePeer(_ recorder: TelnyxCallTimingRecorder) throws -> (Peer, RTCPeerConnection) {
        let peer = Peer(iceServers: InternalConfig.default.prodWebRTCIceServers, timingRecorder: recorder)
        self.peer = peer
        return (peer, try XCTUnwrap(peer.connection))
    }

    func testPeerRecordsSetupMilestonesDuringInit() throws {
        let recorder = TelnyxCallTimingRecorder(direction: .outbound, useTrickleIce: true)
        _ = try makePeer(recorder)

        let labels = stepLabels(recorder.callTimingsLines())
        XCTAssertTrue(labels.contains("Peer object created"))
        XCTAssertTrue(labels.contains("Media devices acquired"))
        XCTAssertTrue(labels.contains("Peer setup complete"))
    }

    func testIceCompletedDoesNotCountAsDtlsConnected() throws {
        let recorder = TelnyxCallTimingRecorder(direction: .outbound, useTrickleIce: true)
        let (peer, connection) = try makePeer(recorder)

        peer.peerConnection(connection, didChange: RTCIceConnectionState.completed)

        let labels = stepLabels(recorder.callTimingsLines())
        XCTAssertTrue(labels.contains("ICE connection established"))
        XCTAssertFalse(labels.contains("Secure media channel established (DTLS)"))
    }

    func testDtlsConnectedComesFromPeerConnectionState() throws {
        let recorder = TelnyxCallTimingRecorder(direction: .outbound, useTrickleIce: true)
        let (peer, connection) = try makePeer(recorder)

        peer.peerConnection(connection, didChange: RTCPeerConnectionState.connected)

        XCTAssertTrue(stepLabels(recorder.callTimingsLines()).contains("Secure media channel established (DTLS)"))
    }

    /// The stats reporter owns these callbacks; timing must work without replacing them.
    func testTimingDoesNotReplaceExistingPeerCallbacks() throws {
        let recorder = TelnyxCallTimingRecorder(direction: .outbound, useTrickleIce: true)
        let (peer, connection) = try makePeer(recorder)
        var iceConnectionEvents = 0
        var iceGatheringEvents = 0
        peer.onIceConnectionChange = { _ in iceConnectionEvents += 1 }
        peer.onIceGatheringChange = { _ in iceGatheringEvents += 1 }

        peer.peerConnection(connection, didChange: RTCIceGatheringState.gathering)
        peer.peerConnection(connection, didChange: RTCIceGatheringState.complete)
        peer.peerConnection(connection, didChange: RTCIceConnectionState.connected)

        XCTAssertEqual(iceGatheringEvents, 2)
        XCTAssertEqual(iceConnectionEvents, 1)
        let labels = stepLabels(recorder.callTimingsLines())
        XCTAssertTrue(labels.contains("ICE candidate gathering started"))
        XCTAssertTrue(labels.contains("All ICE candidates gathered"))
        XCTAssertTrue(labels.contains("ICE connection established"))
    }

    func testServerReflexiveOrRelayCandidateDetection() {
        let base = "candidate:842163049 1 udp 1677729535 203.0.113.7 54321 typ"
        XCTAssertTrue(Peer.isServerReflexiveOrRelay("\(base) srflx raddr 0.0.0.0 rport 0 generation 0"))
        XCTAssertTrue(Peer.isServerReflexiveOrRelay("\(base) relay raddr 198.51.100.2 rport 3478"))
        XCTAssertFalse(Peer.isServerReflexiveOrRelay("\(base) host generation 0"))
        XCTAssertFalse(Peer.isServerReflexiveOrRelay("\(base) prflx"))
        XCTAssertFalse(Peer.isServerReflexiveOrRelay("candidate:1 1 udp 1 203.0.113.7 54321"))
    }
}

// MARK: - Call report wiring

class CallTimingsReportTests: XCTestCase {

    private func makeInboundCall(callReportLogLevel: String = "debug", isAttach: Bool = false) -> Call {
        Call(callId: UUID(),
             remoteSdp: "v=0\r\n",
             sessionId: "<sessionId>",
             socket: Socket(),
             delegate: self,
             iceServers: InternalConfig.default.prodWebRTCIceServers,
             isAttach: isAttach,
             callReportLogLevel: callReportLogLevel)
    }

    private func callTimingsMessages(_ call: Call) -> [String] {
        (call.callReportCollector?.getLogs() ?? [])
            .map(\.message)
            .filter { $0.hasPrefix("[CallTimings]") }
    }

    func testInboundCallAddsCallTimingsBlockWhenActiveAndDtlsConnected() {
        let call = makeInboundCall()

        call.timingRecorder?.record(.dtlsConnected)
        call.updateCallState(callState: .ACTIVE)

        XCTAssertEqual(stepLabels(callTimingsMessages(call)), [
            "Call Start", "Invite received", "Secure media channel established (DTLS)", "Call is active"
        ])
    }

    /// Like the JS SDK, a call that ends before it is active has no `[CallTimings]` block.
    func testCallThatEndsBeforeBecomingActiveHasNoCallTimingsBlock() {
        let call = makeInboundCall()

        call.timingRecorder?.record(.dtlsConnected)
        call.updateCallState(callState: .DONE(reason: nil))

        XCTAssertTrue(callTimingsMessages(call).isEmpty)
    }

    func testCallTimingsAreKeptWhenReportLogLevelIsHigher() {
        let call = makeInboundCall(callReportLogLevel: "error")

        call.timingRecorder?.record(.dtlsConnected)
        call.updateCallState(callState: .ACTIVE)

        XCTAssertFalse(callTimingsMessages(call).isEmpty)
        XCTAssertFalse(call.callReportCollector?.getLogs().contains { $0.message == "Call state changed" } ?? true,
                       "Other info logs must still follow the configured level")
    }

    func testReattachedCallsAreNotTimed() {
        let call = makeInboundCall(isAttach: true)

        call.updateCallState(callState: .DONE(reason: nil))

        XCTAssertNil(call.timingRecorder)
        XCTAssertTrue(callTimingsMessages(call).isEmpty)
    }

    func testOutboundCallStartsTimingAtInviteAndPassesItToPeer() {
        let call = Call(callId: UUID(),
                        sessionId: "<sessionId>",
                        socket: Socket(),
                        delegate: self,
                        iceServers: InternalConfig.default.prodWebRTCIceServers)
        XCTAssertNil(call.timingRecorder)

        call.newCall(callerName: "callerName", callerNumber: "callerNumber", destinationNumber: "destinationNumber")

        let lines = call.timingRecorder?.callTimingsLines() ?? []
        XCTAssertTrue(lines.allSatisfy { $0.hasPrefix("[CallTimings][outbound][standard]") })
        XCTAssertTrue(stepLabels(lines).contains("Peer object created"))
        call.peer?.connection?.close()
    }
}

extension CallTimingsReportTests: CallProtocol {
    func callStateUpdated(call: Call) {}
}
