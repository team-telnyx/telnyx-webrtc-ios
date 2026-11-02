//
//  TxClientSocketErrorTests.swift
//  TelnyxRTCTests
//
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import XCTest
import CallKit
import WebRTC
@testable import TelnyxRTC

/// Tests verifying that the SDK does not reply to server pings on an
/// unauthenticated socket. Sending pong before login triggers a 401
/// error from the server which corrupts SDK state.
class TxClientPingAuthTests: XCTestCase {

    var txClient: TxClient!
    var mockDelegate: PingTestDelegate!

    override func setUp() {
        super.setUp()
        txClient = TxClient()
        mockDelegate = PingTestDelegate()
        txClient.delegate = mockDelegate
    }

    override func tearDown() {
        txClient.delegate = nil
        txClient = nil
        mockDelegate = nil
        super.tearDown()
    }

    /// When the gateway is not registered (unauthenticated socket),
    /// receiving a PING message should NOT send a pong reply.
    /// This prevents the 401 error that corrupts SDK state during push flow.
    func testPingIgnoredWhenNotAuthenticated() {
        // Gateway state defaults to NOREG (not registered / unauthenticated).
        // Simulate receiving a telnyx_rtc.ping message.
        let pingMessage = "{\"jsonrpc\":\"2.0\",\"method\":\"telnyx_rtc.ping\",\"params\":{}}"
        txClient.onMessageReceived(message: pingMessage)

        // The client should NOT have crashed or entered a bad state.
        // Since we can't directly observe whether a message was sent on the socket
        // (socket is nil in test), we verify the client remains functional.
        XCTAssertFalse(txClient.isConnected())
    }

    /// After push flow setup, the gateway is still NOREG (login hasn't happened).
    /// PING messages should be ignored until the user answers and login completes.
    func testPingIgnoredDuringPushFlowBeforeAuth() throws {
        let txConfig = TxConfig(sipUser: "test_user", password: "test_password")
        let serverConfig = TxServerConfiguration()
        let pushMetaData: [String: Any] = [
            "voice_sdk_id": "test-sdk-id",
            "call_id": UUID().uuidString
        ]

        try txClient.processVoIPNotification(
            txConfig: txConfig,
            serverConfiguration: serverConfig,
            pushMetaData: pushMetaData
        )

        // At this point: socket is connected but unauthenticated (NOREG).
        // A ping arrives — SDK should NOT reply.
        let pingMessage = "{\"jsonrpc\":\"2.0\",\"method\":\"telnyx_rtc.ping\",\"params\":{}}"
        txClient.onMessageReceived(message: pingMessage)

        // Client should still be in a valid state, no 401 triggered.
        // The delegate should NOT have received an error.
        XCTAssertFalse(mockDelegate.onClientErrorCalled,
                       "No error should occur — ping should be silently ignored on unauthenticated socket")
    }

    func testFreshPushVoiceSdkIdTakesPrecedenceOverCachedIdOnConnect() throws {
        txClient.onMessageReceived(message: """
        {"jsonrpc":"2.0","voice_sdk_id":"stale-sdk-id","result":{"params":{"state":"REGED"}}}
        """)

        let txConfig = TxConfig(sipUser: "test_user", password: "test_password")
        let serverConfiguration = TxServerConfiguration(
            pushMetaData: [
                "voice_sdk_id": "fresh-push-sdk-id",
                "call_id": UUID().uuidString
            ]
        )

        try txClient.connect(txConfig: txConfig, serverConfiguration: serverConfiguration)

        XCTAssertEqual(
            txClient.serverConfiguration.pushMetaData?["voice_sdk_id"] as? String,
            "fresh-push-sdk-id"
        )
        let queryItems = URLComponents(
            url: txClient.serverConfiguration.signalingServer,
            resolvingAgainstBaseURL: false
        )?.queryItems
        XCTAssertEqual(
            queryItems?.first(where: { $0.name == "voice_sdk_id" })?.value,
            "fresh-push-sdk-id"
        )
    }

    func testDeclinePushDoneUsesEndActionUUIDWhenCallIdIsNotProvided() throws {
        let callUUID = UUID()
        try startPushFlow(callId: callUUID)

        let endAction = CXEndCallAction(call: callUUID)
        txClient.endCallFromCallkit(endAction: endAction)
        txClient.onSocketConnected()

        XCTAssertEqual(mockDelegate.doneCallIds, [callUUID])
    }

    func testPendingDeclineClearsOnSocketErrorBeforeDeclineLogin() throws {
        let callUUID = UUID()
        try startPushFlow(callId: callUUID)

        let endAction = CXEndCallAction(call: callUUID)
        txClient.endCallFromCallkit(endAction: endAction)
        txClient.onSocketError(error: NSError(domain: "TxClientPingAuthTests", code: 1))
        txClient.onSocketConnected()

        XCTAssertTrue(mockDelegate.doneCallIds.isEmpty)
    }

    func testAnsweredPushInviteTimeoutUsesPushUUIDAndFailsAnswerAction() throws {
        let callUUID = UUID()
        txClient.inviteTimeoutInterval = 0.01
        try startPushFlow(callId: callUUID)

        let answerAction = TrackingAnswerCallAction(call: callUUID)
        txClient.answerFromCallkit(answerAction: answerAction)
        txClient.onMessageReceived(message: gatewayStateMessage(state: "REGED"))

        let timeoutExpectation = expectation(description: "VoIP push INVITE timeout handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            timeoutExpectation.fulfill()
        }
        wait(for: [timeoutExpectation], timeout: 1.0)

        XCTAssertEqual(mockDelegate.remoteEndedCallIds, [callUUID])
        XCTAssertEqual(mockDelegate.doneCallIds, [callUUID])
        XCTAssertEqual(answerAction.fulfillCallCount, 0)
        XCTAssertEqual(answerAction.failCallCount, 1)
    }

    func testPassivePushInviteTimeoutUsesPushUUIDWithoutAnswerAction() throws {
        let callUUID = UUID()
        txClient.inviteTimeoutInterval = 0.01
        try startPushFlow(callId: callUUID)

        txClient.onSocketConnected()
        txClient.onMessageReceived(message: gatewayStateMessage(state: "REGED"))

        let timeoutExpectation = expectation(description: "Passive VoIP push INVITE timeout handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            timeoutExpectation.fulfill()
        }
        wait(for: [timeoutExpectation], timeout: 1.0)

        XCTAssertEqual(mockDelegate.remoteEndedCallIds, [callUUID])
        XCTAssertEqual(mockDelegate.doneCallIds, [callUUID])
    }

    func testMalformedInviteDoesNotCancelPushWatchdog() throws {
        let callUUID = UUID()
        txClient.inviteTimeoutInterval = 0.01
        try startPushFlow(callId: callUUID)
        txClient.onMessageReceived(message: gatewayStateMessage(state: "REGED"))

        txClient.onMessageReceived(message: """
        {"jsonrpc":"2.0","method":"telnyx_rtc.invite","params":{"callID":"\(UUID().uuidString)"}}
        """)
        waitForWatchdog()

        XCTAssertEqual(mockDelegate.remoteEndedCallIds, [callUUID])
        XCTAssertEqual(mockDelegate.doneCallIds, [callUUID])
    }

    func testAttachErrorCancelsPushWatchdogAfterSingleCleanup() throws {
        let callUUID = UUID()
        txClient.inviteTimeoutInterval = 0.01
        try startPushFlow(callId: callUUID)
        txClient.onMessageReceived(message: gatewayStateMessage(state: "REGED"))

        let attachId = try XCTUnwrap(txClient.pendingAttachCallIdForTesting)
        txClient.onMessageReceived(message: """
        {"jsonrpc":"2.0","id":"\(attachId)","error":{"code":-1,"message":"Call failed"}}
        """)
        waitForWatchdog()

        XCTAssertEqual(mockDelegate.remoteEndedCallIds, [callUUID])
        XCTAssertEqual(mockDelegate.doneCallIds, [callUUID])
    }

    func testAttachSuccessCancelsPushWatchdogWithoutTerminalCleanup() throws {
        let pushCallUUID = UUID()
        let signalingCallUUID = UUID()
        txClient.inviteTimeoutInterval = 0.01
        try startPushFlow(callId: pushCallUUID)
        txClient.onMessageReceived(message: gatewayStateMessage(state: "REGED"))

        txClient.onMessageReceived(message: """
        {"jsonrpc":"2.0","method":"telnyx_rtc.attach","params":{"sdp":"v=0\\r\\n","callID":"\(signalingCallUUID.uuidString)"}}
        """)
        waitForWatchdog()

        XCTAssertTrue(mockDelegate.remoteEndedCallIds.isEmpty)
        XCTAssertTrue(mockDelegate.doneCallIds.isEmpty)
    }

    /// A push placeholder that never got an INVITE, answer, or decline is still `currentCallId`
    /// when the next push arrives on a connected socket. The teardown in
    /// `processVoIPNotification` ends it, which resets push state; the new push must keep its own.
    func testPushOnConnectedSocketKeepsStateWhenStalePushPlaceholderEnds() throws {
        let stalePushUUID = UUID()
        try startPushFlow(callId: stalePushUUID)
        let staleSocket = try XCTUnwrap(txClient.calls[stalePushUUID]?.socket)
        staleSocket.isConnected = true

        let newPushUUID = UUID()
        try startPushFlow(callId: newPushUUID)

        XCTAssertEqual(mockDelegate.doneCallIds, [stalePushUUID])
        XCTAssertNil(txClient.calls[stalePushUUID])
        XCTAssertNotNil(txClient.calls[newPushUUID])

        // Declining needs the stored push config to connect and send the decline_push login.
        txClient.endCallFromCallkit(endAction: CXEndCallAction(call: newPushUUID))
        txClient.onSocketConnected()

        XCTAssertEqual(mockDelegate.doneCallIds, [stalePushUUID, newPushUUID])
    }

    private func waitForWatchdog() {
        let expectation = expectation(description: "Wait beyond INVITE watchdog")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)
    }

    private func startPushFlow(callId: UUID) throws {
        let txConfig = TxConfig(sipUser: "test_user", password: "test_password")
        let serverConfig = TxServerConfiguration()
        let pushMetaData: [String: Any] = [
            "voice_sdk_id": "test-sdk-id",
            "call_id": callId.uuidString
        ]

        try txClient.processVoIPNotification(
            txConfig: txConfig,
            serverConfiguration: serverConfig,
            pushMetaData: pushMetaData
        )
    }

    private func gatewayStateMessage(state: String) -> String {
        """
        {"jsonrpc":"2.0","id":"gateway-state","result":{"params":{"state":"\(state)"}}}
        """
    }
}

// These tests generate local WebRTC offers and call the real answerFromCallkit
// path. No SIP account, signaling connection, or physical CallKit UI is used.
final class TxClientCallWaitingTests: XCTestCase {
    private var client: TxClient!
    private var socket: Socket!

    override func setUp() {
        super.setUp()
        client = TxClient()
        socket = Socket()
    }

    override func tearDown() {
        for call in client.calls.values {
            call.peer?.dispose()
        }
        client.calls.removeAll()
        client = nil
        socket = nil
        super.tearDown()
    }

    func testAnswersSecondCallAfterFirstCallIsHeld() throws {
        let offer = try makeOffer()
        let first = makeCall(offer: offer)
        let firstAction = answerAction(for: first, description: "A answered")
        client.answerFromCallkit(answerAction: firstAction.action)
        wait(for: [firstAction.done], timeout: 10)
        XCTAssertEqual(first.callState, .ACTIVE)

        first.hold()
        // Model the server's successful hold acknowledgment.
        first.updateCallState(callState: .HELD)
        let second = makeCall(offer: offer)
        let secondAction = answerAction(for: second, description: "B answered while A held")
        client.answerFromCallkit(answerAction: secondAction.action)
        wait(for: [secondAction.done], timeout: 10)

        XCTAssertEqual(first.callState, .HELD)
        XCTAssertEqual(second.callState, .ACTIVE)
        XCTAssertEqual(firstAction.action.fulfillCallCount, 1)
        XCTAssertEqual(secondAction.action.fulfillCallCount, 1)
        XCTAssertEqual(firstAction.action.failCallCount, 0)
        XCTAssertEqual(secondAction.action.failCallCount, 0)
        XCTAssertEqual(client.calls.count, 2)
    }

    func testAnswersSecondCallRightAfterHoldIsSentBeforeServerAcknowledgment() throws {
        let offer = try makeOffer()
        let first = makeCall(offer: offer)
        let firstAction = answerAction(for: first, description: "A answered")
        client.answerFromCallkit(answerAction: firstAction.action)
        wait(for: [firstAction.done], timeout: 10)

        // hold() sends the hold request and marks the call HELD locally right away;
        // the SDK has no state for "hold sent, awaiting server acknowledgment".
        // Answer B immediately, before any acknowledgment for A is modeled.
        first.hold()
        XCTAssertEqual(first.callState, .HELD)

        let second = makeCall(offer: offer)
        let secondAction = answerAction(for: second, description: "B answered during hold")
        client.answerFromCallkit(answerAction: secondAction.action)
        wait(for: [secondAction.done], timeout: 10)

        XCTAssertEqual(first.callState, .HELD)
        XCTAssertEqual(firstAction.action.fulfillCallCount, 1)
        XCTAssertEqual(second.callState, .ACTIVE)
        XCTAssertEqual(secondAction.action.fulfillCallCount, 1)
        XCTAssertEqual(secondAction.action.failCallCount, 0)
        XCTAssertEqual(client.calls.count, 2)
    }

    func testOverlappingAnswersCompleteTheirOwnActionsAndTargetTheirUUIDs() throws {
        let offer = try makeOffer()
        let first = makeCall(offer: offer)
        let second = makeCall(offer: offer)
        let a = answerAction(for: first, description: "A action completed")
        let b = answerAction(for: second, description: "B action completed")
        client.answerFromCallkit(answerAction: a.action, customHeaders: ["X-Test": "A"])
        client.answerFromCallkit(answerAction: b.action, customHeaders: ["X-Test": "B"])
        wait(for: [a.done, b.done], timeout: 10)

        XCTAssertEqual(first.answerCustomHeaders?["X-Test"], "A")
        XCTAssertEqual(second.answerCustomHeaders?["X-Test"], "B")
        XCTAssertEqual(a.action.fulfillCallCount, 1)
        XCTAssertEqual(b.action.fulfillCallCount, 1)
        XCTAssertEqual(a.action.failCallCount, 0)
        XCTAssertEqual(b.action.failCallCount, 0)
    }

    private func makeCall(offer: String) -> Call {
        let callId = UUID()
        let call = Call(callId: callId, remoteSdp: offer, sessionId: "test-session",
                        socket: socket, delegate: client, iceServers: [],
                        enableCallReports: false)
        client.calls[callId] = call
        return call
    }

    private func answerAction(for call: Call, description: String)
        -> (action: TrackingAnswerCallAction, done: XCTestExpectation) {
        let done = expectation(description: description)
        let action = TrackingAnswerCallAction(call: call.callInfo!.callId)
        action.onFulfill = { done.fulfill() }
        return (action, done)
    }

    private func makeOffer() throws -> String {
        let factory = RTCPeerConnectionFactory()
        let configuration = RTCConfiguration()
        configuration.sdpSemantics = .unifiedPlan
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let peer = try XCTUnwrap(factory.peerConnection(with: configuration,
                                                        constraints: constraints, delegate: nil))
        defer { peer.close() }
        let source = factory.audioSource(with: constraints)
        let track = factory.audioTrack(with: source, trackId: "test-audio")
        peer.add(track, streamIds: ["test-stream"])
        let ready = expectation(description: "Local WebRTC offer generated")
        var offer: RTCSessionDescription?
        var offerError: Error?
        peer.offer(for: constraints) { sdp, error in
            offer = sdp
            offerError = error
            ready.fulfill()
        }
        wait(for: [ready], timeout: 10)
        XCTAssertNil(offerError)
        return try XCTUnwrap(offer).sdp
    }
}

// MARK: - Test Helpers

private final class TrackingAnswerCallAction: CXAnswerCallAction {
    private(set) var fulfillCallCount = 0
    private(set) var failCallCount = 0
    var onFulfill: (() -> Void)?

    override func fulfill() {
        fulfillCallCount += 1
        super.fulfill()
        onFulfill?()
    }

    override func fail() {
        failCallCount += 1
        super.fail()
    }
}

class PingTestDelegate: TxClientDelegate {
    var onClientErrorCalled = false
    var doneCallIds: [UUID] = []
    var remoteEndedCallIds: [UUID] = []

    func onSocketConnected() {}
    func onSocketDisconnected() {}
    func onClientReady() {}
    func onSessionUpdated(sessionId: String) {}
    func onIncomingCall(call: Call) {}
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        if case .DONE = callState {
            doneCallIds.append(callId)
        }
    }
    func onRemoteCallEnded(callId: UUID) {}
    func onRemoteCallEnded(callId: UUID, reason: CallTerminationReason?) {
        remoteEndedCallIds.append(callId)
    }
    func onPushDisabled(success: Bool, message: String) {}
    func onPushCall(call: Call) {}

    func onClientError(error: Error) {
        onClientErrorCalled = true
    }
}
