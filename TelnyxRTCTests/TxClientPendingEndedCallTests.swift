//
//  TxClientPendingEndedCallTests.swift
//  TelnyxRTCTests
//
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import XCTest
import WebRTC
@testable import TelnyxRTC

final class TxClientPendingEndedCallTests: XCTestCase {

    private var client: TxClient!
    private var delegate: PendingHangupDelegate!
    private var signalingSocket: PendingHangupSocket!

    override func setUp() {
        super.setUp()
        signalingSocket = PendingHangupSocket(connected: true)
        client = TxClient()
        client.injectSignalingForTesting(socket: signalingSocket,
                                         sessionId: "test-session")
        delegate = PendingHangupDelegate()
        client.delegate = delegate
    }

    override func tearDown() {
        for call in client.calls.values {
            call.peer?.dispose()
        }
        client.calls.removeAll()
        client.delegate = nil
        client = nil
        delegate = nil
        signalingSocket = nil
        super.tearDown()
    }

    func testLocalHangupRetainsSignalingIdEvenWhenInitialByeWasSent() {
        let appCallId = UUID()
        let signalingCallId = UUID()
        let socket = PendingHangupSocket(connected: true)
        let call = makeCall(appCallId: appCallId,
                            signalingCallId: signalingCallId,
                            socket: socket)
        client.calls[appCallId] = call
        call.updateCallState(callState: .ACTIVE)

        call.hangup()

        XCTAssertEqual(socket.byeMessages.count, 1)
        XCTAssertNil(client.calls[appCallId])

        client.onMessageReceived(message: gatewayStateMessage())
        XCTAssertTrue(signalingSocket.byeMessages.isEmpty)

        client.onMessageReceived(message: attachMessage(callId: signalingCallId))
        XCTAssertEqual(signalingSocket.byeMessages.count, 1)
        XCTAssertTrue(client.calls.isEmpty)
    }

    func testRegedRetriesPendingByeWithoutAttach() throws {
        let callId = UUID()
        hangup(callId: callId, connected: false)

        client.onMessageReceived(message: gatewayStateMessage())

        XCTAssertEqual(signalingSocket.byeMessages.count, 1)
        try assertBye(signalingSocket.byeMessages[0],
                      callId: callId,
                      sessionId: client.getSessionId(),
                      causeCode: .NORMAL_CLEARING)

        client.disconnect()
        client.injectSignalingForTesting(socket: signalingSocket,
                                         sessionId: "another-session")
        client.onMessageReceived(message: gatewayStateMessage())

        XCTAssertEqual(signalingSocket.byeMessages.count, 1)
    }

    func testPendingByeAllowsReconnectWithoutActiveCall() {
        client.txConfig = TxConfig(sipUser: "test-user", password: "test-password")
        client.onMessageReceived(message: gatewayStateMessage())

        hangup(callId: UUID(), connected: false)
        client.reconnectClient()

        XCTAssertEqual(signalingSocket.reconnectRequests, [true])
    }

    func testPendingByeReconnectsWhenGatewayIsNotNoreg() {
        client.txConfig = TxConfig(sipUser: "test-user", password: "test-password")
        client.onMessageReceived(message: gatewayStateMessage(state: "TRYING"))

        hangup(callId: UUID(), connected: false)
        client.reconnectClient()

        XCTAssertEqual(signalingSocket.reconnectRequests, [true])
    }

    func testAttachForLocallyEndedCallRetriesByeWithoutRestoringCall() throws {
        let callId = UUID()
        hangup(callId: callId, connected: false)

        client.onMessageReceived(message: attachMessage(callId: callId))

        XCTAssertEqual(signalingSocket.byeMessages.count, 1)
        try assertBye(signalingSocket.byeMessages[0],
                      callId: callId,
                      sessionId: client.getSessionId(),
                      causeCode: .NORMAL_CLEARING)
        XCTAssertTrue(client.calls.isEmpty)
        XCTAssertTrue(delegate.incomingCallIds.isEmpty)

        // A duplicate ATTACH retries the idempotent BYE and still cannot
        // resurrect the locally ended call.
        client.onMessageReceived(message: attachMessage(callId: callId))
        XCTAssertEqual(signalingSocket.byeMessages.count, 2)
        XCTAssertTrue(client.calls.isEmpty)
    }

    func testAttachUsesSignalingIdWhenAppCallIdDiffers() throws {
        let appCallId = UUID()
        let signalingCallId = UUID()
        let socket = PendingHangupSocket(connected: false)
        let call = makeCall(appCallId: appCallId,
                            signalingCallId: signalingCallId,
                            socket: socket)
        client.calls[appCallId] = call
        call.updateCallState(callState: .ACTIVE)
        call.hangup()

        client.onMessageReceived(message: attachMessage(callId: signalingCallId))

        XCTAssertEqual(signalingSocket.byeMessages.count, 1)
        try assertBye(signalingSocket.byeMessages[0],
                      callId: signalingCallId,
                      sessionId: client.getSessionId(),
                      causeCode: .NORMAL_CLEARING)
        XCTAssertTrue(client.calls.isEmpty)
    }

    func testRejectRetainsBusyCause() throws {
        let callId = UUID()
        let socket = PendingHangupSocket(connected: false)
        let call = makeCall(appCallId: callId, socket: socket)
        client.calls[callId] = call

        call.hangup()

        client.onMessageReceived(message: attachMessage(callId: callId))
        try assertBye(XCTUnwrap(signalingSocket.byeMessages.first),
                      callId: callId,
                      sessionId: client.getSessionId(),
                      causeCode: .USER_BUSY)
    }

    func testUnrelatedAttachStillRestoresLiveCall() {
        let endedCallId = UUID()
        hangup(callId: endedCallId, connected: false)

        let liveCallId = UUID()
        client.onMessageReceived(message: attachMessage(callId: liveCallId))

        XCTAssertNotNil(client.calls[liveCallId])
        XCTAssertTrue(signalingSocket.byeMessages.isEmpty)
    }

    func testNewPushTransportResetPreservesEarlierLocalHangup() throws {
        let endedCallId = UUID()
        hangup(callId: endedCallId, connected: false)

        let newerPushCallId = UUID()
        try client.processVoIPNotification(
            txConfig: TxConfig(sipUser: "test-user", password: "test-password"),
            serverConfiguration: TxServerConfiguration(),
            pushMetaData: [
                "voice_sdk_id": "newer-push-sdk-id",
                "call_id": newerPushCallId.uuidString
            ]
        )

        client.injectSignalingForTesting(socket: signalingSocket,
                                         sessionId: "reattached-session")
        client.onMessageReceived(message: attachMessage(callId: endedCallId))

        XCTAssertEqual(signalingSocket.byeMessages.count, 1)
        XCTAssertNil(client.calls[endedCallId])

        // A's late ATTACH must not reset the newer push B flow.
        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","result":{"params":{"state":"REGED"}}}
        """)
        XCTAssertNotNil(client.pendingAttachCallIdForTesting)
    }

    func testExplicitDisconnectPreservesLocalHangups() {
        let endedCallId = UUID()
        hangup(callId: endedCallId, connected: false)

        client.disconnect()
        client.injectSignalingForTesting(socket: signalingSocket,
                                         sessionId: "new-logical-session")
        client.onMessageReceived(message: attachMessage(callId: endedCallId))

        XCTAssertEqual(signalingSocket.byeMessages.count, 1)
        XCTAssertNil(client.calls[endedCallId])
    }

    func testExplicitDisconnectWaitsForExplicitReconnectBeforeSendingPendingBye() {
        client.txConfig = TxConfig(sipUser: "test-user", password: "test-password")
        client.onMessageReceived(message: gatewayStateMessage())

        let endedCallId = UUID()
        hangup(callId: endedCallId, connected: false)
        client.disconnect()

        client.reconnectClient()
        XCTAssertEqual(signalingSocket.reconnectRequests, [false])
        XCTAssertTrue(signalingSocket.byeMessages.isEmpty)

        client.injectSignalingForTesting(socket: signalingSocket,
                                         sessionId: "explicit-reconnect-session")
        client.onMessageReceived(message: gatewayStateMessage())

        XCTAssertEqual(signalingSocket.byeMessages.count, 1)
        XCTAssertNil(client.calls[endedCallId])
    }

    func testLocalHangupsAreLimitedToMostRecentSixteenCalls() {
        let callIds = (0..<17).map { _ in UUID() }
        callIds.forEach { hangup(callId: $0, connected: false) }

        callIds.forEach {
            client.onMessageReceived(message: attachMessage(callId: $0))
        }

        XCTAssertNotNil(client.calls[callIds[0]])
        XCTAssertEqual(signalingSocket.byeMessages.count, 16)
        XCTAssertNil(client.calls[callIds[16]])
    }

    private func makeCall(appCallId: UUID,
                          signalingCallId: UUID? = nil,
                          socket: Socket) -> Call {
        Call(callId: appCallId,
             signalingCallId: signalingCallId,
             remoteSdp: "v=0\r\n",
             sessionId: "session-1",
             socket: socket,
             delegate: client,
             iceServers: [],
             enableCallReports: false)
    }

    private func hangup(callId: UUID, connected: Bool) {
        let socket = PendingHangupSocket(connected: connected)
        let call = makeCall(appCallId: callId, socket: socket)
        client.calls[callId] = call
        call.updateCallState(callState: .ACTIVE)
        call.hangup()
    }

    private func attachMessage(callId: UUID) -> String {
        "{\"jsonrpc\":\"2.0\",\"method\":\"telnyx_rtc.attach\",\"params\":{\"sdp\":\"v=0\\r\\n\",\"callID\":\"\(callId.uuidString)\"}}"
    }

    private func gatewayStateMessage(state: String = "REGED") -> String {
        "{\"jsonrpc\":\"2.0\",\"result\":{\"params\":{\"state\":\"\(state)\"}}}"
    }

    private func assertBye(_ message: String,
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
        XCTAssertEqual(dialogParams["callID"] as? String,
                       callId.uuidString.lowercased())
    }
}

private final class PendingHangupSocket: Socket {
    private(set) var sentMessages: [String] = []
    private(set) var reconnectRequests: [Bool] = []

    init(connected: Bool) {
        super.init()
        isConnected = connected
    }

    override func sendMessage(message: String?) {
        guard isConnected, let message = message else { return }
        sentMessages.append(message)
    }

    override func disconnect(reconnect: Bool) {
        reconnectRequests.append(reconnect)
    }

    var byeMessages: [String] {
        sentMessages.filter { $0.contains(Method.BYE.rawValue) }
    }
}

private final class PendingHangupDelegate: TxClientDelegate {
    var incomingCallIds: [UUID] = []

    func onSocketConnected() {}
    func onSocketDisconnected() {}
    func onClientReady() {}
    func onSessionUpdated(sessionId: String) {}
    func onIncomingCall(call: Call) {
        if let callId = call.callInfo?.callId {
            incomingCallIds.append(callId)
        }
    }
    func onCallStateUpdated(callState: CallState, callId: UUID) {}
    func onRemoteCallEnded(callId: UUID) {}
    func onRemoteCallEnded(callId: UUID, reason: CallTerminationReason?) {}
    func onPushDisabled(success: Bool, message: String) {}
    func onPushCall(call: Call) {}
    func onClientError(error: Error) {}
}
