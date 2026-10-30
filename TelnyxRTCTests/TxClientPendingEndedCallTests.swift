//
//  TxClientPendingEndedCallTests.swift
//  TelnyxRTCTests
//
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import XCTest
import WebRTC
@testable import TelnyxRTC

/// Regression tests for hanging up while the signaling socket is down.
///
/// `Socket.sendMessage` silently drops messages when the socket is
/// disconnected, so a hangup BYE can be lost. A later `attach_call=true`
/// login may then reattach the already-ended call, leaving the caller on a
/// dead leg. The SDK must preserve the termination intent (`Call.byeMayBeLost`),
/// retain it when the call reaches DONE (`TxClient.callsEndedWithoutBye`), and
/// reconcile the pending termination over a reattached signaling session
/// instead of restoring the ended call locally.
final class TxClientPendingEndedCallTests: XCTestCase {

    private var client: TxClient!
    private var mockDelegate: RecordingTxClientDelegate!

    override func setUp() {
        super.setUp()
        client = TxClient()
        mockDelegate = RecordingTxClientDelegate()
        client.delegate = mockDelegate
    }

    override func tearDown() {
        for call in client.calls.values {
            call.peer?.dispose()
        }
        client.calls.removeAll()
        client.delegate = nil
        client = nil
        mockDelegate = nil
        super.tearDown()
    }

    // MARK: - Connected hangup keeps existing behavior

    func testConnectedHangupDeliversByeAndLeavesNoPendingRecord() {
        let socket = RecordingSocket(connected: true)
        let callId = UUID()
        let call = makeCall(callId: callId, socket: socket)
        client.calls[callId] = call
        call.updateCallState(callState: .ACTIVE)

        call.hangup()

        // The BYE is delivered over the connected socket, exactly as before.
        XCTAssertEqual(socket.byeMessages.count, 1)
        XCTAssertFalse(call.byeMayBeLost)
        // The call is still removed locally and no pending record is created.
        XCTAssertNil(client.calls[callId])
        XCTAssertTrue(client.callsEndedWithoutBye.isEmpty)
    }

    // MARK: - Socket-down hangup preserves the termination intent

    func testSocketDownHangupRecordsPendingEndedCallAfterLocalRemoval() throws {
        let socket = RecordingSocket(connected: false)
        let callId = UUID()
        let call = makeCall(callId: callId, socket: socket)
        client.calls[callId] = call
        call.updateCallState(callState: .ACTIVE)

        call.hangup()

        // The BYE was silently dropped by the disconnected socket...
        XCTAssertTrue(socket.sentMessages.isEmpty)
        // ...so the termination intent is preserved on the call...
        XCTAssertTrue(call.byeMayBeLost)
        // ...and retained by the client even after the local call was removed.
        XCTAssertNil(client.calls[callId])
        let record = try XCTUnwrap(client.callsEndedWithoutBye[callId])
        XCTAssertEqual(record.appFacingCallId, callId)
        XCTAssertEqual(record.signalingCallId, callId)
        XCTAssertEqual(record.causeCode, CauseCode.NORMAL_CLEARING)
        XCTAssertFalse(record.reconciled)
        // The application still observes the local DONE state.
        XCTAssertEqual(mockDelegate.doneCallIds, [callId])
    }

    // MARK: - Reattach reconciliation

    func testAttachAfterReconnectTerminatesRemoteLegWithoutRestoringCall() throws {
        // Phase 1: hangup while the signaling socket is down.
        let callId = UUID()
        hangupWhileSocketDown(callId: callId)

        // Phase 2: the session is reestablished and the server reattaches
        // the already-ended call.
        let reattachedSocket = RecordingSocket(connected: true)
        client.injectSignalingForTesting(socket: reattachedSocket, sessionId: "session-2")
        client.onMessageReceived(message: attachMessage(callId: callId))

        // The pending BYE is delivered over the reattached session...
        XCTAssertEqual(reattachedSocket.byeMessages.count, 1)
        try assertReconciledBye(reattachedSocket.byeMessages[0],
                                callId: callId,
                                sessionId: "session-2",
                                causeCode: CauseCode.NORMAL_CLEARING)
        // ...the ended call is NOT restored locally...
        XCTAssertTrue(client.calls.isEmpty)
        XCTAssertTrue(mockDelegate.incomingCallIds.isEmpty)
        XCTAssertTrue(mockDelegate.activeCallIds.isEmpty)
        // ...and the record is marked reconciled so repeated ATTACH cannot re-fire.
        XCTAssertTrue(try XCTUnwrap(client.callsEndedWithoutBye[callId]).reconciled)

        // Repeated ATTACH is safe: no duplicate BYE and no resurrection.
        client.onMessageReceived(message: attachMessage(callId: callId))
        XCTAssertEqual(reattachedSocket.byeMessages.count, 1)
        XCTAssertTrue(client.calls.isEmpty)
    }

    func testAttachWhileSocketStillDownDefersByeToNextReattach() throws {
        let callId = UUID()
        hangupWhileSocketDown(callId: callId)

        // First reconnect attempt: the socket is still down, so the pending
        // BYE cannot be delivered yet.
        let firstReconnectSocket = RecordingSocket(connected: false)
        client.injectSignalingForTesting(socket: firstReconnectSocket, sessionId: "session-2")
        client.onMessageReceived(message: attachMessage(callId: callId))

        XCTAssertFalse(try XCTUnwrap(client.callsEndedWithoutBye[callId]).reconciled)
        XCTAssertTrue(firstReconnectSocket.sentMessages.isEmpty)
        // The ended call must not be resurrected even without delivery.
        XCTAssertTrue(client.calls.isEmpty)
        XCTAssertTrue(mockDelegate.incomingCallIds.isEmpty)

        // Second reconnect: the socket is up and the pending BYE is retried.
        let reattachedSocket = RecordingSocket(connected: true)
        client.injectSignalingForTesting(socket: reattachedSocket, sessionId: "session-3")
        client.onMessageReceived(message: attachMessage(callId: callId))

        XCTAssertEqual(reattachedSocket.byeMessages.count, 1)
        try assertReconciledBye(reattachedSocket.byeMessages[0],
                                callId: callId,
                                sessionId: "session-3",
                                causeCode: CauseCode.NORMAL_CLEARING)
        XCTAssertTrue(try XCTUnwrap(client.callsEndedWithoutBye[callId]).reconciled)
        XCTAssertTrue(client.calls.isEmpty)
    }

    func testAttachForSignalingCallIdReconcilesMismatchedAppFacingId() throws {
        // Push-style call: the app-facing call ID differs from the signaling one.
        let appFacingId = UUID()
        let signalingId = UUID()
        let socket = RecordingSocket(connected: false)
        let call = makeCall(callId: appFacingId,
                            socket: socket,
                            signalingCallId: signalingId)
        client.calls[appFacingId] = call
        call.updateCallState(callState: .ACTIVE)

        call.hangup()

        // The record is retained under BOTH identities.
        XCTAssertNotNil(client.callsEndedWithoutBye[appFacingId])
        XCTAssertNotNil(client.callsEndedWithoutBye[signalingId])

        // The server reattaches using the signaling identity.
        let reattachedSocket = RecordingSocket(connected: true)
        client.injectSignalingForTesting(socket: reattachedSocket, sessionId: "session-2")
        client.onMessageReceived(message: attachMessage(callId: signalingId))

        XCTAssertEqual(reattachedSocket.byeMessages.count, 1)
        // The reconciled BYE targets the signaling identity.
        try assertReconciledBye(reattachedSocket.byeMessages[0],
                                callId: signalingId,
                                sessionId: "session-2",
                                causeCode: CauseCode.NORMAL_CLEARING)
        XCTAssertTrue(client.calls.isEmpty)
        XCTAssertTrue(mockDelegate.incomingCallIds.isEmpty)
        // Both aliases point at the same reconciled record.
        XCTAssertTrue(try XCTUnwrap(client.callsEndedWithoutBye[appFacingId]).reconciled)
        XCTAssertTrue(try XCTUnwrap(client.callsEndedWithoutBye[signalingId]).reconciled)
    }

    // MARK: - Still-live calls keep reattaching normally

    func testAttachForLiveCallStillCreatesIncomingCall() {
        let reattachedSocket = RecordingSocket(connected: true)
        client.injectSignalingForTesting(socket: reattachedSocket, sessionId: "session-1")

        let liveCallId = UUID()
        client.onMessageReceived(message: attachMessage(callId: liveCallId))

        // Unrelated live calls keep reattaching normally: the call is restored
        // locally and no reconciliation BYE is sent for it.
        XCTAssertNotNil(client.calls[liveCallId])
        XCTAssertTrue(client.callsEndedWithoutBye.isEmpty)
        XCTAssertTrue(reattachedSocket.byeMessages.isEmpty)
        // The reattach itself does not fabricate terminal or ACTIVE state events.
        XCTAssertTrue(mockDelegate.doneCallIds.isEmpty)
        XCTAssertTrue(mockDelegate.activeCallIds.isEmpty)
    }

    // MARK: - Helpers

    private func makeCall(callId: UUID,
                          socket: Socket,
                          signalingCallId: UUID? = nil) -> Call {
        return Call(callId: callId,
                    signalingCallId: signalingCallId,
                    remoteSdp: "v=0\r\n",
                    sessionId: "test-session",
                    socket: socket,
                    delegate: client,
                    iceServers: [],
                    enableCallReports: false)
    }

    private func hangupWhileSocketDown(callId: UUID) {
        let socket = RecordingSocket(connected: false)
        let call = makeCall(callId: callId, socket: socket)
        client.calls[callId] = call
        call.updateCallState(callState: .ACTIVE)
        call.hangup()
    }

    private func attachMessage(callId: UUID) -> String {
        return "{\"jsonrpc\":\"2.0\",\"method\":\"telnyx_rtc.attach\",\"params\":{\"sdp\":\"v=0\\r\\n\",\"callID\":\"\(callId.uuidString)\"}}"
    }

    private func assertReconciledBye(_ message: String,
                                     callId: UUID,
                                     sessionId: String,
                                     causeCode: CauseCode) throws {
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(message.utf8)) as? [String: Any]
        )
        XCTAssertEqual(json["method"] as? String, Method.BYE.rawValue)
        let params = try XCTUnwrap(json["params"] as? [String: Any])
        XCTAssertEqual(params["sessId"] as? String, sessionId)
        XCTAssertEqual(params["causeCode"] as? Int, causeCode.rawValue)
        let dialogParams = try XCTUnwrap(params["dialogParams"] as? [String: Any])
        XCTAssertEqual(dialogParams["callID"] as? String, callId.uuidString.lowercased())
    }
}

// MARK: - Test Doubles

private final class RecordingSocket: Socket {
    private(set) var sentMessages: [String] = []

    init(connected: Bool) {
        super.init()
        self.isConnected = connected
    }

    override func sendMessage(message: String?) -> Bool {
        guard let message = message, isConnected else {
            return false
        }
        sentMessages.append(message)
        return true
    }

    var byeMessages: [String] {
        return sentMessages.filter { $0.contains(Method.BYE.rawValue) }
    }
}

private final class RecordingTxClientDelegate: TxClientDelegate {
    var doneCallIds: [UUID] = []
    var incomingCallIds: [UUID] = []
    var activeCallIds: [UUID] = []
    var remoteEndedCallIds: [UUID] = []

    func onSocketConnected() {}
    func onSocketDisconnected() {}
    func onClientReady() {}
    func onSessionUpdated(sessionId: String) {}
    func onIncomingCall(call: Call) {
        if let callId = call.callInfo?.callId {
            incomingCallIds.append(callId)
        }
    }
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        switch callState {
        case .DONE:
            doneCallIds.append(callId)
        case .ACTIVE:
            activeCallIds.append(callId)
        default:
            break
        }
    }
    func onRemoteCallEnded(callId: UUID) {}
    func onRemoteCallEnded(callId: UUID, reason: CallTerminationReason?) {
        remoteEndedCallIds.append(callId)
    }
    func onPushDisabled(success: Bool, message: String) {}
    func onPushCall(call: Call) {}
    func onClientError(error: Error) {}
}
