//
//  TxClientSocketErrorTests.swift
//  TelnyxRTCTests
//
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import XCTest
import CallKit
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

    /// VSUP-308: an answer with no push in flight and no call must not be kept for the next push INVITE.
    func testAnswerWithoutPushOrCallFailsAfterInviteTimeout() {
        let staleCallUUID = UUID()
        txClient.inviteTimeoutInterval = 0.01

        let answerAction = TrackingAnswerCallAction(call: staleCallUUID)
        txClient.answerFromCallkit(answerAction: answerAction)
        waitForWatchdog()

        XCTAssertEqual(answerAction.failCallCount, 1)
        XCTAssertEqual(answerAction.fulfillCallCount, 0)
        XCTAssertFalse(txClient.hasPendingAnswerActionForTesting)
        XCTAssertEqual(mockDelegate.remoteEndedCallIds, [staleCallUUID])
        XCTAssertEqual(mockDelegate.doneCallIds, [staleCallUUID])
    }

    func testNextPushDoesNotInheritExpiredAnswer() throws {
        txClient.inviteTimeoutInterval = 0.01
        let answerAction = TrackingAnswerCallAction(call: UUID())
        txClient.answerFromCallkit(answerAction: answerAction)
        waitForWatchdog()

        try startPushFlow(callId: UUID())

        XCTAssertFalse(txClient.hasPendingAnswerActionForTesting)
        XCTAssertEqual(answerAction.failCallCount, 1)
    }

    /// Apps can report the call to CallKit and get the answer before calling `processVoIPNotification`.
    func testAnswerBeforeProcessVoIPNotificationIsKeptForThePush() throws {
        let callUUID = UUID()
        txClient.inviteTimeoutInterval = 0.01

        let answerAction = TrackingAnswerCallAction(call: callUUID)
        txClient.answerFromCallkit(answerAction: answerAction)
        try startPushFlow(callId: callUUID)
        waitForWatchdog()

        XCTAssertTrue(txClient.hasPendingAnswerActionForTesting)
        XCTAssertEqual(answerAction.failCallCount, 0)
        XCTAssertTrue(mockDelegate.doneCallIds.isEmpty)
    }

    /// A stale answer still waiting on its INVITE timeout must be failed and cleared when
    /// the next push arrives (socket down, so no connected-socket teardown), and must not
    /// survive into that push flow (VSUP-308).
    func testStaleAnswerFailedWhenNextPushArrivesBeforeTimeout() throws {
        let staleCallUUID = UUID()
        let newPushUUID = UUID()
        txClient.inviteTimeoutInterval = 0.01

        let staleAnswerAction = TrackingAnswerCallAction(call: staleCallUUID)
        txClient.answerFromCallkit(answerAction: staleAnswerAction)
        try startPushFlow(callId: newPushUUID)
        waitForWatchdog()

        XCTAssertEqual(staleAnswerAction.failCallCount, 1)
        XCTAssertEqual(staleAnswerAction.fulfillCallCount, 0)
        XCTAssertFalse(txClient.hasPendingAnswerActionForTesting)
        // The stale call is resolved by the failed CallKit action - no DONE or remote-ended
        // events are emitted for it, and the new push flow keeps its own placeholder.
        XCTAssertTrue(mockDelegate.remoteEndedCallIds.isEmpty)
        XCTAssertTrue(mockDelegate.doneCallIds.isEmpty)
        XCTAssertNotNil(txClient.calls[newPushUUID])
    }

    /// The INVITE watchdog armed for push call A must not terminate the newer push flow B
    /// that arrived before A's timer fired (VSUP-308).
    func testStaleInviteTimerCannotTerminateNextPushFlow() throws {
        let stalePushUUID = UUID()
        let newPushUUID = UUID()
        txClient.inviteTimeoutInterval = 0.01

        // Push flow for A, answered and registered - arms the INVITE watchdog for A.
        try startPushFlow(callId: stalePushUUID)
        txClient.onSocketConnected()
        let staleAnswerAction = TrackingAnswerCallAction(call: stalePushUUID)
        txClient.answerFromCallkit(answerAction: staleAnswerAction)
        txClient.onMessageReceived(message: gatewayStateMessage(state: "REGED"))

        // The next push arrives BEFORE A's watchdog fires. The socket is down, so the
        // connected-socket teardown does not run and A's timer stays armed.
        try startPushFlow(callId: newPushUUID)
        waitForWatchdog()

        // A's answer was failed and cleared by the new push...
        XCTAssertEqual(staleAnswerAction.failCallCount, 1)
        XCTAssertEqual(staleAnswerAction.fulfillCallCount, 0)
        XCTAssertFalse(txClient.hasPendingAnswerActionForTesting)
        // ...and A's delayed watchdog did not terminate the newer push flow.
        XCTAssertTrue(mockDelegate.remoteEndedCallIds.isEmpty)
        XCTAssertTrue(mockDelegate.doneCallIds.isEmpty)
        XCTAssertNotNil(txClient.calls[newPushUUID])
    }

    /// A pending CallKit answer for a different call must not be consumed to auto-answer
    /// this push INVITE (VSUP-308): the stale action is failed and the push call is
    /// propagated to the app without being answered.
    func testMismatchedPendingAnswerIsFailedInsteadOfAutoAnsweringPushInvite() throws {
        let pushCallUUID = UUID()
        try startPushFlow(callId: pushCallUUID)

        // CallKit answer for an unrelated call arrives after the push was processed.
        let staleAnswerAction = TrackingAnswerCallAction(call: UUID())
        txClient.answerFromCallkit(answerAction: staleAnswerAction)

        // INVITE for the push flow arrives - signaling callID differs from the push call_id.
        txClient.onMessageReceived(message: """
        {"jsonrpc":"2.0","method":"telnyx_rtc.invite","params":{"sdp":"v=0\\r\\n","callID":"\(UUID().uuidString)","caller_id_name":"","caller_id_number":"","telnyx_session_id":"","telnyx_leg_id":""}}
        """)

        XCTAssertEqual(staleAnswerAction.failCallCount, 1)
        XCTAssertEqual(staleAnswerAction.fulfillCallCount, 0)
        XCTAssertFalse(txClient.hasPendingAnswerActionForTesting)
        // The push call was created and propagated, but not auto-answered.
        XCTAssertNotNil(txClient.calls[pushCallUUID])
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

// MARK: - Test Helpers

private final class TrackingAnswerCallAction: CXAnswerCallAction {
    private(set) var fulfillCallCount = 0
    private(set) var failCallCount = 0

    override func fulfill() {
        fulfillCallCount += 1
        super.fulfill()
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
